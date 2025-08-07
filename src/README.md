# Source code
Let's install, build and run!

Contents:\
[Preliminary notes](#preliminary-notes)\
[Overview](#overview)\
[Install](#install)\
[Set up Docker](#set-up-docker)\
[Reproduce](#reproduce)\



## Preliminary notes
1. All software is tested on a machine running Ubuntu 20.04.6 LTS with Robot Operating System (ROS) Noetic. The setup should work on other Ubuntu versions as well, but we cannot guarantee this. If you encounter any issues, please let us know by creating an issue in this repository.

2. Note that some links in this and other READMEs do not work on [github.com](https://github.com). To view the links, clone the repository including all its submodules and open the READMEs in your favourite editor.

3. Interested in using this setup for your own system? This is certainly possible! Our [MPC](./catkin_ws/src/mpc) package can easily be extended to other robotic platforms and tasks by defining different models, objectives, constraints, etc. Furthermore, it supports data logging, visualization, and real-time performance evaluation.



## Overview
The setup consists of several submodules, each with its own purpose.

> :information_source: The submodule links below are relative to this directory and do not work in the browser with the current version of GitHub (see https://github.com/orgs/community/discussions/51141). Either manually navigate to the submodule in the browser or clone the repository recursively and click on the links in your IDE.

| **Package** | **Description** |
|-------------|-----------------|
| [**agiclean**](./catkin_ws/src/agiclean) | Custom version of the [Agilicious](https://github.com/uzh-rpg/agilicious) stack. |
| [**DecompUtil**](./catkin_ws/src/DecompUtil) | Convex decomposition algorithm used to construct convex obstacle-free regions per stage in the MPC horizon. |
| [**catkin_simple**](./catkin_ws/src/catkin_simple) | See [this page](https://github.com/catkin/catkin_simple?tab=readme-ov-file#readme) for more information. |
| [**eigen_catkin**](./catkin_ws/src/eigen_catkin) | See [this page](https://github.com/ethz-asl/eigen_catkin?tab=readme-ov-file#readme) for more information. |
| [**gazebo_ros_pkgs**](./catkin_ws/src/gazebo_ros_pkgs) | See [this page](https://github.com/dbenders1/gazebo_ros_pkgs?tab=readme-ov-file#readme) for more information. |
| [**mav_comm**](./catkin_ws/src/mav_comm) | See [this page](https://github.com/ethz-asl/mav_comm?tab=readme-ov-file#readme) for more information. |
| [**mpc**](./catkin_ws/src/mpc) | Modular MPC code framework used for trajectory optimization of nonlinear mobile robots. |
| [**mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp**](./catkin_ws/src/mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp) | MATLAB code to run the offline robust and terminal ingredients design. |
| [**mpc_model_id_mismatch**](./catkin_ws/src/mpc_model_id_mismatch) | Python package to identify model coefficients, determine model mismatch, and determine robust MPC tightening constants. |
| [**occupancygrid_creator**](./catkin_ws/src/occupancygrid_creator) | ROS package to create an occupancy grid from the geometrical shape of obstacles, either statically defined or received via a motion capture system. |
| [**rohmpc-data-analysis**](./catkin_ws/src/rohmpc-data-analysis) | Python package to closed-loop MPC data. |
| [**rosbag2json**](./catkin_ws/src/rosbag2json) | ROS package to convert ROS bags to JSON files. |
| [**rotors_simulator**](./catkin_ws/src/rotors_simulator) | See [this page](https://github.com/tud-amr/rotors_simulator?tab=readme-ov-file#readme) for more information. |
| [**simple_sim**](./catkin_ws/src/simple_sim) | Simple simulation environment to simulate system dynamics with and without disturbances and measurement noise. |



## Install
### GitHub
We recommend setting up your connection with GitHub using SSH. See [this page](https://docs.github.com/en/authentication/connecting-to-github-with-ssh) for more information.


### Docker
Install [Docker](https://docs.docker.com/) by following the instructions on [this page](https://docs.docker.com/get-started/get-docker). Give Docker sudo rights by following the instructions on [this page](https://docs.docker.com/engine/install/linux-postinstall/).


### Python 3
The solver generation code in the [MPC](./catkin_ws/src/mpc) repository requires Python 3. See the [MPC README](./catkin_ws/src/mpc/README.md) for more information.


### ForcesPro license
The MPC implementations use a ForcesPro solver. Therefore, first request a ForcesPro license and install the client. To this end, follow the corresponding instructions in the [MPC README](./catkin_ws/src/mpc/README.md).


### MATLAB and packages
Please refer to the [MPC-SDP README](./catkin_ws/src/mpc/mpc_solver/scripts/include/offline_computations/mpc-sdp/README.md) for the MATLAB version and packages that were used to run the offline terminal ingredients design.


### Access to agiclean
The [agiclean](./catkin_ws/src/agiclean) package provides a custom version of the [Agilicious](https://github.com/uzh-rpg/agilicious) stack. For using the Agilicious stack a license is required, see [this page](https://agilicious.readthedocs.io/en/latest/index.html) for more information. After obtaining the license, you can request access to [agiclean](./catkin_ws/src/agiclean) by contacting [Sihao Sun](https://sihaosun.github.io/).



## Set up Docker
To set up the Docker container, following the instructions below:
1. Go to the `src` directory of this repo:
    ```bash
    cd src
    ```

2. Build the Docker image by filling in the required arguments:
    ```bash
    sudo ./docker_build.sh
    ```
    Give the Docker image a descriptive name, such as *agi*.

3. Create and run container from the built image by filling in the required arguments:
    ```bash
    ./docker_run.sh
    ```
    Give the Docker container a descriptive name, such as *johndoe-paper-rohmpc* and provide an arbitrary number for the Falcon ID, for example 7. From now on, we refer to the container with this name.

4. Start the [tmuxinator](https://github.com/tmuxinator/tmuxinator) project [*rohmpc.yml*](./config_files/.tmuxinator/rohmpc.yml):
    ```bash
    tmuxinator start rohmpc
    ```
    This will start a pre-defined [tmux](https://github.com/tmux/tmux/wiki) session with the name *rohmpc* providing several useful terminal windows. Attach to the running tmux session using `arohmpc` and kill it using `krohmpc`.

    > :information_source: Compared to the default tmux settings, we have changed the prefix key to `Ctrl-a` for convenience of usage, see the [tmux.conf](./config_files/dotfiles/.tmux.conf) file for more information.



## Reproduce
If everything is correctly installed, all steps in the pipeline should run out of the box. These steps include:
1. [Uncertainty quantification](./uq.md)
2. [Robust and terminal ingredients design](./robust_term_design.md)
3. [Tightening calibration](./tightening_calib.md)
4. [ROHMPC deployment and analysis](./rohmpc.md)
