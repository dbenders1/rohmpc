# ROHMPC deployment and analysis
Contents:\
[High-level information](#high-level-information)\
[Deploy the ROHMPC framework](#deploy-the-rohmpc-framework)\
[Reproduce plot in paper](#reproduce-plot-in-paper)



## High-level information
- Purpose: the [tightening calibration](./tightening_calib.md) should give non-empty input and state constraint sets for the PMPC and TMPC schemes. Therefore, we can now use all offline-computed results so far to build the PMPC and TMPC solvers, deploy the resulting ROHMPC framework, and analyze its properties.
- Inputs: model parameters, estimated disturbance bias $\bm{w}^\mathrm{b}$, robust and terminal ingredients stored in [offline_design.mat](./catkin_ws/src/mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp/offline_design.mat) and calibrated tightening constants stored in [tightening.json](./catkin_ws/src/mpc_model_id_mismatch/data/tightening_results/tightening.json).
- Outputs: a plot showing that the closed-loop system is contained in both the PMPC and TMPC tubes, thus robustly satisfies constraints, and the observation that the complete framework is recursively feasible.



## Deploy the ROHMPC framework
The closed-loop ROHMPC data is already stored in [2025-08-08_gaz_falcon_rohmpc.bag](./catkin_ws/src/rosbag2json/data/recorded_bags/2025-08-08_gaz_falcon_rohmpc.bag) and [2025-08-08_11-47__ReferenceTrajectory_StaticPolyhedronConstraints_0.json](./catkin_ws/src/mpc/mpc_tools/recorded_data/2025-08-08_11-47__ReferenceTrajectory_StaticPolyhedronConstraints_0.json). To reproduce this result, follow the instructions below:
1. Since the current PMPC and TMPC exclude constraint tightening and terminal sets, we need to generate the ForcesPro code for PMPC and TMPC with constraint tightening and terminal sets. To do this:
    - Ensure that the following parameters are set correctly in [tmpc_settings.py](./catkin_ws/src/mpc/mpc_solver/scripts/systems/falcon/tmpc_settings.py):
      - Set `model_options["use_tightened_system_constraints"]` to `True`
      - Set `model_options["use_tightened_obstacle_constraints"]` to `True`
      - Set `model_options["use_terminal_set_constraint"]` to `True`
    - Ensure that the following parameters are set correctly in [pmpc_settings.py](./catkin_ws/src/mpc/mpc_solver/scripts/systems/falcon/pmpc_settings.py):
      - Set `model_options["use_tightened_system_constraints"]` to `True`
      - Set `model_options["use_tightened_obstacle_constraints"]` to `True`
      - Set `model_options["use_terminal_steady_state_constraint"]` to `True`
    - In a separate terminal on the host machine, generate the ROHMPC solver:
      ```bash
      agi_gen_rohmpc_solver_x86
      ```

2. Ensure that the following parameters are set correctly:
    - [main.launch](./catkin_ws/src/agiclean/agiros/agiros/launch/simulation/main.launch):
      - Set `gazebo_x_init` to -1.5 and `gazebo_y_init` to -0.5
      - Set `mpc_occupancy_grid_map_file` to `map_falcon_rohmpc_with_obstacles.yaml`
    - [common.yaml](./catkin_ws/src/mpc/mpc_systems/mpc_falcon/config/common.yaml):
      - Set `goals_trajectory` to `none`
      - Set `goals_x` to `[-0.5]`
      - Set `goals_y` to `[-0.5]`
      - Set `goals_z` to `[1]`
      - Set `goals_yaw` to `[0]` (yaw is not supported in this framework yet)
    - [falcon_hmpc.yaml](./catkin_ws/src/mpc/mpc_systems/mpc_falcon/config/falcon_hmpc.yaml):
      - Set `use_nominal_reference` to `false`
    - [rotors_sim_pilot_mpc.yaml](./catkin_ws/src/agiclean/agiros/agiros/parameters/rotors_sim_pilot_mpc.yaml):
      - Set `auto_enable_ext_control` to `true`

3. Build the catkin workspace in the *build* window of the tmux session:
    ```bash
    catkin build agiros
    ```

4. Record data of the closed-loop ROHMPC framework by taking the following steps:
    - Start the PMPC scheme by running the following command in the bottom-left pane in tmux window *run*:
        ```bash
        run_gaz_2_1
        ```
    - When the PMPC scheme is running, i.e., ForcesPro license is verified without getting `License error (exit_code = -100)`, start the TMPC scheme by running the following command in the top-left pane in tmux window *run*:
        ```bash
        run_gaz_2_base
        ```
    This simulation shows the obstacle avoidance constraints, the predicted trajectories, and the quadrotor motion while moving from start to goal position.



## Reproduce plot in paper
The plot included in the paper is stored as [rohmpc.pdf](./catkin_ws/src/rohmpc-data-analysis/data/figures/rohmpc.pdf). To reproduce this plots, follow these steps:
1. Copy the ROS bag file recorded in the previous section to the [recorded_bags](./catkin_ws/src/rosbag2json/data/recorded_bags) directory by running the following command in the top-right pane in tmux window *run*:
    ```bash
    cp <bag_name>.bag ~/catkin_ws/src/rosbag2json/data/recorded_bags/2025-08-08_gaz_falcon_rohmpc.bag
    ```

2. Convert the ROS bag to a JSON file by adding it to [rosbag2json.yaml](./catkin_ws/src/rosbag2json/config/scripts/rosbag2json.yaml) under `# Bag files to evaluate ROHMPC framework below` and running [rosbag2json.py](./catkin_ws/src/rosbag2json/scripts/rosbag2json.py) in a separate terminal on your host machine.

3. Set the following parameters in [print_plot_rohmpc_data.yaml](./catkin_ws/src/rohmpc-data-analysis/config/scripts/print_plot_rohmpc_data.yaml):
   - Set `runtime_json_name` to the last generated JSON file in the [recorded_data](./catkin_ws/src/mpc/mpc_tools/recorded_data) directory:
        ```yaml
        runtime_json_name: 2025-08-08_11-47__ReferenceTrajectory_StaticPolyhedronConstraints_0
        ```
    - Set `ros_rec_json_names` to the last generated JSON file in the [converted_bags](./catkin_ws/src/rosbag2json/data/converted_bags) directory:
        ```yaml
        ros_rec_json_name: 2025-08-08_gaz_falcon_rohmpc
        ```
    - Set `save_settings/save_fig` to `true`
    - Set `fig_name` to `rohmpc`

4. In a separate terminal on your host machine, run the following commands to set up and activate the virtual environment in the [rohmpc-data-analysis](./catkin_ws/src/rohmpc-data-analysis) package:
    ```bash
    cd <path_to_rohmpc-data-analysis>
    ./setup_venv.sh
    source venv/bin/activate
    ```
    where `<path_to_rohmpc-data-analysis>` is the path to the [rohmpc-data-analysis](./catkin_ws/src/rohmpc-data-analysis) directory on your host machine.

5. Run [print_plot_rohmpc_data.py](./catkin_ws/src/rohmpc-data-analysis/scripts/print_plot_rohmpc_data.py):
    ```bash
    python scripts/print_plot_rohmpc_data.py
    ```
    This will create the [rohmpc.pdf](./catkin_ws/src/rohmpc-data-analysis/data/figures/rohmpc.pdf) file.

:white_check_mark: That's it! You made it till the very end, good job! :clap:

Now it's time to start experimenting with different settings to actually understand what is happening :stuck_out_tongue_winking_eye:
