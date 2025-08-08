# Uncertainty quantification
Contents:\
[High-level information](#high-level-information)\
[Reproduce collecting input-output data](#reproduce-collecting-input-output-data)\
[Reproduce estimated uncertainty bounds](#reproduce-estimated-uncertainty-bounds)\
[Reproduce plots in paper](#reproduce-plots-in-paper)



## High-level information
- Purpose: estimate bounds on disturbances and measurement noise. In this case, the ground truth measurement noise bounds are known, used as constraints in the optimization problem, and saved as outputs.
- Inputs: input-output data of the closed-loop system with the MPC controller provided in [agiclean](./catkin_ws/src/agiclean).
- Outputs: estimated bounds on disturbances and measurement noise, saved in [falcon_t.mat](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.mat) (for the [robust and terminal ingredients design](./robust_term_design.md)) and [falcon_t.json](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.json) (for plotting).



## Reproduce collecting input-output data
The recorded input-output data is already stored in the repository as ROS bag files and JSON files in the [recorded_bags](./catkin_ws/src/rosbag2json/data/recorded_bags) and [converted_bags](./catkin_ws/src/rosbag2json/data/converted_bags) directories. If you want to reproduce the steps to collect the input-output data, follow the instructions below:
1. Generate a clockwise circular trajectory with radius 1 and frequency 0.3 Hz. To do this:
    - Ensure that the last uncommented code in [symbolic_trajectory.py](./catkin_ws/src/agiclean/agiros/quadrotor_trajectory_generation/utils/symbolic_trajectory.py) corresponds to the desired trajectory.
    - Match the speedup time and duration times in brackets with the values in [settings.yaml](./catkin_ws/src/agiclean/agiros/quadrotor_trajectory_generation/config/settings.yaml).
    - In the top-left pane in tmux window *run*, press `arrow-up` until you can run the following command:
    ```bash
    gen_traj
    ```
    - This will generate a csv file containing the trajectory data in the [generated_trajectories](./catkin_ws/src/agiclean/agiros/quadrotor_trajectory_generation/generated_trajectories) directory.
    - Copy the file to the home directory in the container by running:
    ```bash
    cp catkin_ws/src/agiclean/agiros/quadrotor_trajectory_generation/generated_trajectories/<csv_name>.csv ~/traj_circle_r1_f0dot3_cw.csv
    ```
    and replacing `<csv_name>` with the name of the generated csv file.
    - You can repeat these steps to generate the counter-clockwise circular trajectory and clockwise and counter-clockwise lemniscate trajectories with the same radius and frequency. Take care to choose the correct speedup and duration times and use the following names for the generated files:
      - *traj_circle_r1_f0dot3_ccw.csv* for the counter-clockwise circular trajectory
      - *traj_leminscate_r1_f0dot3_cw.csv* for the clockwise lemniscate trajectory
      - *traj_leminscate_r1_f0dot3_ccw.csv* for the counter-clockwise lemniscate trajectory

2. Ensure that the built-in MPC controller in Agilicious is used to track the trajectory by setting `auto_enable_ext_control` to `false` in [rotors_sim_pilot_mpc.yaml](./catkin_ws/src/agiclean/agiros/agiros/parameters/rotors_sim_pilot_mpc.yaml).

3. Ensure you have a stable internet connection. Due to the code structure, the MPC controller belonging to the work in this paper needs to verify the ForcesPro license upon construction of the controller class. This requires an internet connection. Restart the simulation if you see the following warning message: `License error (exit_code = -100)`.

4. Check that the `gazebo_x_init` and `gazebo_y_init` arguments in [main.launch](./catkin_ws/src/agiclean/agiros/agiros/launch/simulation/main.launch) are set to 0, so that the Gazebo simulation starts at the origin.

5. Check that the correct trajectory is selected in [main.launch](./catkin_ws/src/agiclean/agiros/agiros/launch/simulation/main.launch). To do this, set the `traj_file_name` argument to the name of the trajectory file you generated in step 1. For example, if you generated the clockwise circular trajectory, set it to `traj_circle_r1_f0dot3_cw.csv`.

6. In the top-left pane in tmux window *run*, press `arrow-up` until you can run the following command:
    ```bash
    run_gaz_2_base
    ```
    This will start the Gazebo simulation with the Falcon quadrotor and the built-in MPC controller tracking the trajectory. Let the quadrotor fly at least 2 circles (or lemniscates) before stopping the simulation.
    > :exclamation: Ensure that you do not see `No updated command received at t=...` being printed in the terminal. The Gazebo simulation is set up to run deterministically, so all commands first need to be received before the simulator can take the next step. If this is not the case, this error message is printed. Rerun the simulation in that case.

7. The simulation will automatically record a ROS bag. Copy the bag file to the [recorded_bags](./catkin_ws/src/rosbag2json/data/recorded_bags) directory by running the following command in the top-right pane in tmux window *run*:
    ```bash
    cp <bag_name>.bag ~/catkin_ws/src/rosbag2json/data/recorded_bags/2025-08-07_gaz_falcon_model_mismatch_traj_circle_r1_f0dot3_cw.bag
    ```
    Replace `<bag_name>` with the name of the bag file, which is printed the last in the terminal when you run `ls -al --sort=time -r` (selected after pressing `arrow-up` a few times).
    > :exclamation: The name format of the bag file is important since it is automatically parsed in several scripts. Make sure to comply with it!

8. Repeat steps 4-7 for the counter-clockwise circular trajectory and the clockwise and counter-clockwise lemniscate trajectories. Use the following names for the copied bag files:
    - *2025-08-07_gaz_falcon_model_mismatch_traj_circle_r1_f0dot3_ccw.bag* for the counter-clockwise circular trajectory
    - *2025-08-07_gaz_falcon_model_mismatch_traj_lemniscate_r1_f0dot3_cw.bag* for the clockwise lemniscate trajectory
    - *2025-08-07_gaz_falcon_model_mismatch_traj_lemniscate_r1_f0dot3_ccw.bag* for the counter-clockwise lemniscate trajectory

9. Add the ROS bag files that you want to process to `bag_names` in [rosbag2json.yaml](./catkin_ws/src/rosbag2json/config/rosbag2json.yaml) under `# Bag files to determine model mismatch below`. Ensure that this is the only `bag_names` entry uncommented in the file. Also, ensure that the `topic_names` below are also the only ones that are uncommented.

10. Convert the ROS bags to JSON files by running [rosbag2json.py](./catkin_ws/src/rosbag2json/scripts/rosbag2json.py) in a separate terminal on your host machine.
  > :information_source: This requires a working ROS installation that recognizes the messages in the ROS bag that you want to read. To make the uncertainty bounds estimation agnostic to the ROS distribution and Ubuntu version, we have already converted the ROS bags to JSON files and include the resulting JSON files in the repository. This way, the reproducibility only depends on the installation of Python.



## Reproduce estimated uncertainty bounds
The estimated uncertainty bounds are already included in [falcon_t.mat](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.mat) and [falcon_t.json](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.json). If you want to reproduce the steps to estimate them, follow the instructions below:
1. Enter the correct settings in [determine_model_mismatch.yaml](./catkin_ws/src/mpc_model_id_mismatch/config/scripts/determine_model_mismatch.yaml):
    - Ensure that the measurement noise bounds `eta_max` equal the values for `noise_uniform_position` until `noise_uniform_angular_velocity` in [falcon_base.xacro](./catkin_ws/src/agiclean/agiros/agiros/resources/gazebo_files/falcon_base.xacro). These values are used to constrain the measurement noise bounds in the optimization problem.
    - Add the JSON file names that you want to process to `json_names`.
    - Since we want to know how well the scheme estimates the disturbances but we do not know them beforehand for the Gazebo simulation, we need to determine them first. Therefore, set `determine_w` to `true`.
      > :information_source: This will use a similar formulation as the final one, but ignore measurement noise (this gets automatically subtracted from the output data since it is known and recorded via the ROS bag).

      > :information_source: When using [simple_sim](./catkin_ws/src/simple_sim), the disturbances are also recorded in the ROS bag, so there is no need to first determine them. Running such a simulation is easy: just use the `run_sim_2_base` command instead of `run_gaz_2_base`.

2. In a separate terminal on your host machine, run the following commands to set up and activate the virtual environment in the [mpc_model_id_mismatch](./catkin_ws/src/mpc_model_id_mismatch) package:
    ```bash
    cd <path_to_mpc_model_id_mismatch>
    ./setup_venv.sh <path_to_acados_template>
    source venv/bin/activate
    ```
    where `<path_to_mpc_model_id_mismatch>` is the path to the *mpc_model_id_mismatch* directory on your host machine and `<path_to_acados_template>` is the path to the *acados_template* directory on your host machine.

3. In the sourced Python environment, run the following command to determine the disturbances:
    ```bash
    python scripts/determine_model_mismatch.py
    ```
    This will store the disturbance values per JSON file in the [mpc_model_id_mismatch_results](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results) directory.

4. After determining the disturbances, we can run the UQ formulation. To do this, change the following parameters in [determine_model_mismatch.yaml](./catkin_ws/src/mpc_model_id_mismatch/config/scripts/determine_model_mismatch.yaml):
    - Ensure that `n_iter` is set to 2, as explained in the paper
    - Set `determine_w` to `false`
    - Set `use_predetermined_w` to `true` (to use the disturbances that were determined in the previous step for benchmarking)

5. Run the following command to estimate the uncertainty bounds:
    ```bash
    python scripts/determine_model_mismatch.py
    ```
    This will take a while to compute and should print an output with information about the overall disturbance and measurement noise bounds. Furthermore, it should produce the files [falcon_t.mat](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.mat) and [falcon_t.json](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.json) in the [mpc_model_id_mismatch_results](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results) directory.

6. Now, it's time for the next step: the robust and terminal ingredients design. To do this, follow the instructions in [robust_term_design.md](./robust_term_design.md).



## Reproduce plots in paper
The plots included in the paper are stored as [likelihood.pdf](./catkin_ws/src/mpc_model_id_mismatch/data/figures/model_mismatch/likelihood.pdf) and [w_est_gt_ratios_combined.pdf](./catkin_ws/src/mpc_model_id_mismatch/data/figures/model_mismatch/w_est_gt_ratios_combined.pdf). To reproduce the plots, follow these steps:
1. Ensure to give the [falcon_t.mat](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.mat) and [falcon_t.json](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.json) files from the previous step different names, so they can be easily restored without having to determine the model mismatch again.

2. Ensure the following parameters are set in [determine_model_mismatch.yaml](./catkin_ws/src/mpc_model_id_mismatch/config/scripts/determine_model_mismatch.yaml):
    - `json_names: [2025-08-07_gaz_falcon_model_mismatch_traj_circle_r1_f0dot3_cw]`
    - `n_iter` is set to 5
    - `determine_w` is set to `false`
    - `use_predetermined_w` is set to `true`

3. Determine the model mismatch for 5 iterations for this specific trajectory data by running the following command:
    ```bash
    python scripts/determine_model_mismatch.py
    ```
    This will update the files [falcon_t.mat](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.mat) and [falcon_t.json](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.json) in the [mpc_model_id_mismatch_results](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results) directory.

4. To create and store the plots as PDF, ensure to set the following parameters in [plot_model_mismatch_data.yaml](./catkin_ws/src/mpc_model_id_mismatch/config/scripts/plot_model_mismatch_data.yaml):
    - `save_settings/w_est_gt_ratios_combined` to `true`
    - `save_settings/likelihood` to `true`

5. Run the following command to create the plots:
    ```bash
    python scripts/plot_model_mismatch_data.py
    ```

6. Restore the [falcon_t.mat](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.mat) and [falcon_t.json](./catkin_ws/src/mpc_model_id_mismatch/data/model_mismatch_results/falcon_t.json) files computed in the previous section.

:white_check_mark: That's it! You have successfully completed all UQ steps! Let's continue with the [robust and terminal ingredients design](./robust_term_design.md)!
