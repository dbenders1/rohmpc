# Tightening calibration
Contents:\
[High-level information](#high-level-information)\
[Reproduce calibration of $\rho$](#reproduce-calibration-of-$\rho$)\
[Reproduce calibration of $\bar{w}^\mathrm{o}$ and $\epsilon$](#reproduce-calibration-of-$\bar{w}^\mathrm{o}$-and-$\epsilon$)



## High-level information
- Purpose: after the [robust and terminal ingredient design](./robust_term_design.md), the constraint tightening has become so large that only empty input and state sets are left. As a result, solving the PMPC and TMPC problems is infeasible. Therefore, we want to calibrate the constraint tightening based on empirical data. To this end, we first calibrate contraction rate $\rho$, followed by the calibration of tube growth $\bar{w}^\mathrm{o}$ and observer error sublevel set $\epsilon$.
- Inputs: model parameters, estimated disturbance bias $\bm{w}^\mathrm{b}$ and robust and terminal ingredients stored in [offline_design.mat](./catkin_ws/src/mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp/offline_design.mat).
- Outputs: calibrated values for $\rho$, $\bar{w}^\mathrm{o}$ and $\epsilon$ stored in [tightening.json](./catkin_ws/src/mpc_model_id_mismatch/data/tightening_results/tightening.json).



## Reproduce calibration of $\rho$
The calibration of $\rho$ is based on comparing the multi-step prediction of the nominal model with the actual system response when tracking a nominal reference trajectory with just the observer and feedback controller in the loop (without TMPC). The result of this calibration is stored in [tightening.json](./catkin_ws/src/mpc_model_id_mismatch/data/tightening_results/tightening.json). To reproduce this result, follow the instructions below:
1. We first need to collect data of tracking the nominal reference trajectory. Since the model parameters and feedback and observer values need to be known in the code, let's generate the ForcesPro code for PMPC and TMPC without constraint tightening and terminal sets. We need these MPC schemes in the next section anyway. To do this:
    - Ensure that the following parameters are set correctly in [tmpc_settings.py](./catkin_ws/src/mpc/mpc_solver/scripts/systems/falcon/tmpc_settings.py):
      - Set `model_options["use_tightened_system_constraints"]` to `False`
      - Set `model_options["use_tightened_obstacle_constraints"]` to `False`
      - Set `model_options["use_terminal_set_constraint"]` to `False`
    - Ensure that the following parameters are set correctly in [pmpc_settings.py](./catkin_ws/src/mpc/mpc_solver/scripts/systems/falcon/pmpc_settings.py):
      - Set `model_options["use_tightened_system_constraints"]` to `False`
      - Set `model_options["use_tightened_obstacle_constraints"]` to `False`
      - Set `model_options["use_terminal_steady_state_constraint"]` to `False`
    - In a separate terminal on the host machine, generate the ROHMPC solver:
      ```bash
      agi_gen_rohmpc_solver_x86
      ```

2. Ensure that the following parameters are set correctly:
    - [main.launch](./catkin_ws/src/agiclean/agiros/agiros/launch/simulation/main.launch):
      - Set `gazebo_x_init` and `gazebo_y_init` to 0
      - Set `mpc_occupancy_grid_map_file` to `map_falcon_rohmpc_without_obstacles.yaml`
    - [falcon_hmpc.yaml](./catkin_ws/src/mpc/mpc_systems/mpc_falcon/config/falcon_hmpc.yaml):
      - Set `use_nominal_reference` to `true`
    - [rotors_sim_pilot_mpc.yaml](./catkin_ws/src/agiclean/agiros/agiros/parameters/rotors_sim_pilot_mpc.yaml):
      - Set `auto_enable_ext_control` to `true`

3. Build the catkin workspace in the *build* window of the tmux session:
    ```bash
    catkin build agiros
    ```

4. Record a bit more than 10 s of simulation data by running the following command in the top-left pane in tmux window *run*:
    ```bash
    run_gaz_2_base
    ```
    Note that the TMPC runs in the background since it is not disabled in the code. This will return infeasible at some point as the obstacle avoidance constraints are exceeded. Just ignore these messages.

5. Copy the ROS bag file to the [recorded_bags](./catkin_ws/src/rosbag2json/data/recorded_bags) directory by running the following command in the top-right pane in tmux window *run*:
    ```bash
    cp <bag_name>.bag ~/catkin_ws/src/rosbag2json/data/recorded_bags/2025-08-08_gaz_falcon_calibrate_rho_c.bag
    ```

6. Convert the ROS bag to a JSON file by adding it to [rosbag2json.yaml](./catkin_ws/src/rosbag2json/config/scripts/rosbag2json.yaml) under `# Bag files to calibrate tightening below` and running [rosbag2json.py](./catkin_ws/src/rosbag2json/scripts/rosbag2json.py) in a separate terminal on your host machine.

7. Set the following parameters in [determine_tightening.yaml](./catkin_ws/src/mpc_model_id_mismatch/config/scripts/determine_tightening.yaml):
   - Set `runtime_json_names` to the last generated JSON file in the [recorded_data](./catkin_ws/src/mpc/mpc_tools/recorded_data) directory, for example:
        ```yaml
        runtime_json_names: [2025-08-08_08-36__ReferenceTrajectory_StaticPolyhedronConstraints_0]
        ```
    - Set `ros_rec_json_names` to the last generated JSON file in the [rosbag2json/data/converted_bags](./catkin_ws/src/rosbag2json/data/converted_bags) directory, for example:
        ```yaml
        ros_rec_json_names: [2025-08-08_gaz_falcon_calibrate_rho_c]
        ```
    - To reproduce the Lyapunov error plot in the paper, additionally set `save_settings/lyap_err` to `true`

8. Run [determine_tightening](./catkin_ws/src/mpc_model_id_mismatch/scripts/determine_tightening.py) to calibrate $\rho$ by running the following command in the same terminal where the Python virtual environment is activated in the [mpc_model_id_mismatch](./catkin_ws/src/mpc_model_id_mismatch) package:
    ```bash
    python scripts/determine_tightening.py
    ```
    The calibrated value for $\rho$ is printed in the terminal and stored in [tightening.json](./catkin_ws/src/mpc_model_id_mismatch/data/tightening_results/tightening.json). Check [tube_fit.pdf](./catkin_ws/src/mpc_model_id_mismatch/data/figures/tightening/tube_fit.pdf) for the resulting plot.
    > :exclamation: The script [determine_tightening.py](./catkin_ws/src/mpc_model_id_mismatch/scripts/determine_tightening.py) also processes the file name and searches for the string `rho_c` (value of $\rho$ in continuous-time formulation) in the `ros_rec_json_names` entry. If it is not found, the script will not run.



## Reproduce calibration of $\bar{w}^\mathrm{o}$ and $\epsilon$
$\bar{w}^\mathrm{o}$ and $\epsilon$ are calibrated based on the closed-loop system response when tracking similar trajectories to the ones used for the [uncertainty quantification](./uq.md) using the ROHMPC scheme without constraint tightening and terminal sets, as generated in the previous section. The result of this calibration is stored in [tightening.json](./catkin_ws/src/mpc_model_id_mismatch/data/tightening_results/tightening.json). To reproduce this result, follow the instructions below:
1. Ensure that the following parameters are set correctly:
    - [common.yaml](./catkin_ws/src/mpc/mpc_systems/mpc_falcon/config/common.yaml):
      - Set `goals_trajectory` to `circle_r1_f0dot3_cw`
    - [falcon_hmpc.yaml](./catkin_ws/src/mpc/mpc_systems/mpc_falcon/config/falcon_hmpc.yaml):
      - Set `use_nominal_reference` to `false`

2. Record one full trajectory (at least 29 s for circular trajectories; at least 43 s for lemniscate trajectories) by taking the following steps:
    - Start the PMPC scheme by running the following command in the bottom-left pane in tmux window *run*:
      ```bash
      run_gaz_2_1
      ```
    - When the PMPC scheme is running, i.e., ForcesPro license is verified without getting `License error (exit_code = -100)`, start the TMPC scheme by running the following command in the top-left pane in tmux window *run*:
      ```bash
      run_gaz_2_base
      ```

3. Copy the ROS bag file to the [recorded_bags](./catkin_ws/src/rosbag2json/data/recorded_bags) directory by running the following command in the top-right pane in tmux window *run*:
    ```bash
    cp <bag_name>.bag ~/catkin_ws/src/rosbag2json/data/recorded_bags/2025-08-08_gaz_falcon_calibrate_w_bar_c_epsilon_circle_r1_f0dot3_cw.bag
    ```

4. Repeat steps 2 and 3 for the counter-clockwise circular trajectory and clockwise and counter-clockwise lemniscate trajectories.

5. Convert the ROS bag to JSON files by adding them to [rosbag2json.yaml](./catkin_ws/src/rosbag2json/config/scripts/rosbag2json.yaml) under `# Bag files to calibrate tightening below` and running [rosbag2json.py](./catkin_ws/src/rosbag2json/scripts/rosbag2json.py) in a separate terminal on your host machine.

6. Correctly set the parameters in [determine_tightening.yaml](./catkin_ws/src/mpc_model_id_mismatch/config/scripts/determine_tightening.yaml) similar to the ones in the previous section.

7. Run [determine_tightening.py](./catkin_ws/src/mpc_model_id_mismatch/scripts/determine_tightening.py) to calibrate $\bar{w}^\mathrm{o}$ and $\epsilon$ by running the following command in the same terminal where the Python virtual environment is activated in the [mpc_model_id_mismatch](./catkin_ws/src/mpc_model_id_mismatch) package:
    ```bash
    python scripts/determine_tightening.py
    ```
    The calibrated values for $\bar{w}^\mathrm{o}$ and $\epsilon$ are printed in the terminal and stored in [tightening.json](./catkin_ws/src/mpc_model_id_mismatch/data/tightening_results/tightening.json).

:white_check_mark: And another step is done! You have successfully completed the tightening calibration! Let's continue with the [ROHMPC deployment and analysis](./rohmpc.md)!
