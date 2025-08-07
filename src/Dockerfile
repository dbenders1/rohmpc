# Select base image
FROM ros:melodic

# Change the default shell to Bash to run RUN commands in this file
SHELL [ "/bin/bash", "-c" ]

# Set environment variables
# Note: NVIDIA_VISIBLE_DEVICES and NVIDIA_DRIVER_CAPABILITIES for nvidia-container-runtime.
# Adds support to NVIDIA drivers inside the container.
# For this to work, you need to install nvidia-docker2 in your host machine.
# More info: http://wiki.ros.org/docker/Tutorials/Hardware%20Acceleration
ENV DEBIAN_FRONTEND=noninteractive
ENV ROS_ROOT=/opt/ros/$ROS_DISTRO
ENV ROSDEP_SOURCES=/etc/ros/rosdep/sources.list.d
ENV USER=agilicious
ENV HOME=/home/$USER
ENV WS=$HOME/catkin_ws
ENV NVIDIA_VISIBLE_DEVICES=${NVIDIA_VISIBLE_DEVICES:-all}
ENV NVIDIA_DRIVER_CAPABILITIES=${NVIDIA_DRIVER_CAPABILITIES:+$NVIDIA_DRIVER_CAPABILITIES,}graphics

# Add user
RUN useradd -m $USER \
    && echo "$USER:$USER" | chpasswd \
    && usermod --shell /bin/bash $USER \
    && usermod -aG dialout $USER \
    && usermod -aG sudo $USER \
    && usermod -aG tty $USER  \
    # Replace 1000 with your user/group id
    && usermod --uid 1000 $USER \
    && groupmod --gid 1000 $USER \
    && mkdir -p /etc/sudoers.d \
    && echo "$USER ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USER \
    && chmod 0440 /etc/sudoers.d/$USER

# Set user and working directory
USER $USER
WORKDIR $HOME

# Install tool libraries
RUN sudo apt update \
    && sudo apt install -y --no-install-recommends \
        ccache \
        gdb \
        git \
        htop \
        jq \
        iputils-ping \
        libopencv-dev \
        libeigen3-dev \
        libgoogle-glog-dev \
        libyaml-cpp-dev \
        net-tools \
        psmisc \
        screen \
        tmux \
        tmuxinator \
        usbutils \
        vim \
        wget \
    && sudo apt clean \
    && sudo rm -rf /var/lib/apt/lists/*

# Install GCC 9 and set as default GCC compiler
RUN sudo apt update \
    && sudo apt install -y --no-install-recommends software-properties-common \
    && sudo add-apt-repository ppa:ubuntu-toolchain-r/test \
    && sudo apt install -y --no-install-recommends gcc-9 g++-9 \
    && sudo apt clean \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9

# Install CLANG and set as default compiler
RUN sudo apt update \
    && sudo apt install -y --no-install-recommends clang-10
ENV CC=/usr/bin/clang-10
ENV CXX=/usr/bin/clang++-10

# Install Python, Python packages and dependencies
RUN sudo apt update \
    && sudo apt install -y --no-install-recommends \
        python \
        python-pip \
        python3-pip \
        python3-tk \
        python3-venv \
        libblas-dev \
        liblapack-dev \
        gfortran \
    && sudo apt clean \
    && sudo rm -rf /var/lib/apt/lists/* \
    && sudo -H pip install catkin-tools scipy

# Install ROS dependencies
RUN sudo apt update \
    && sudo apt install -y --no-install-recommends \
        ros-$ROS_DISTRO-eigen-conversions \
        ros-$ROS_DISTRO-gazebo-plugins \
        ros-$ROS_DISTRO-mav-msgs \
        ros-$ROS_DISTRO-octomap-msgs \
        ros-$ROS_DISTRO-octomap-ros \
        ros-$ROS_DISTRO-plotjuggler-ros \
        ros-$ROS_DISTRO-rqt \
        ros-$ROS_DISTRO-rqt-graph \
        ros-$ROS_DISTRO-rqt-reconfigure \
        ros-$ROS_DISTRO-rqt-tf-tree \
        ros-$ROS_DISTRO-rviz \
        ros-$ROS_DISTRO-tf-conversions \
        ros-$ROS_DISTRO-tf2-geometry-msgs \
        ros-$ROS_DISTRO-xacro \
    && sudo apt clean \
    && sudo rm -rf /var/lib/apt/lists/*

# Install Gazebo
RUN sudo apt update \
    && sudo apt install -y --no-install-recommends gazebo9 libgazebo9-dev \
    && sudo apt clean \
    && sudo rm -rf /var/lib/apt/lists/*

# Install NuttX dependencies and tools
RUN sudo apt update \
    && sudo apt install -y --no-install-recommends \
        automake \
        bison \
        build-essential \
        flex \
        gcc-arm-none-eabi \
        gperf \
        libncurses5-dev \
        libtool \
        libusb-dev \
        libusb-1.0.0-dev \
        pkg-config \
        dfu-util \
    && sudo apt clean \
    && sudo rm -rf /var/lib/apt/lists/*
RUN mkdir -p ~/nuttx \
    && cd ~/nuttx \
    && git clone https://bitbucket.org/nuttx/tools \
    && cd tools/kconfig-frontends/ \
    && ./configure \
    && make \
    && sudo make install \
    && sudo ldconfig

# Install Betaflight
RUN sudo mkdir /usr/share/desktop-directories/
RUN sudo apt update \
    && sudo apt install -y --no-install-recommends \
        dbus \
        gpg \
        gpg-agent \
        gpgconf \
        gpgv \
        libcanberra-gtk-module \
        libcanberra-gtk3-module \
        libgconf-2-4 \
        libgtk-3-0 \
        libnss3 \
        libx11-xcb1 \
        libxss1 \
        libxtst6 \
        xdg-utils \
    && sudo apt clean \
    && sudo rm -rf /var/lib/apt/lists/*

# Install and configure perf
RUN sudo apt update \
    && sudo apt install -y --no-install-recommends linux-tools-generic \
    && sudo apt clean \
    && sudo rm -rf /var/lib/apt/lists/*
RUN cd /usr/lib/linux-tools \
    && cd `ls -1 | head -n1` \
    && sudo rm -f /usr/bin/perf \
    && sudo ln -s `pwd`/perf /usr/bin/perf

# Copy config files
COPY config_files/.tmuxinator $HOME/.tmuxinator
COPY config_files/dotfiles $HOME
COPY config_files/rosdep_ignore.yaml $ROSDEP_SOURCES

# Copy scripts
RUN mkdir -p $HOME/scripts
COPY scripts $HOME/scripts

# Create catkin workspace
RUN mkdir -p $WS/src \
    && cd $WS \
    && catkin init \
    && catkin config --init --mkdirs --extend $ROS_ROOT --cmake-args -DCMAKE_BUILD_TYPE=Release

# Copy all repositories to make sure dependencies are correctly installed and packages with long build time can be built in advance
COPY catkin_ws/src $WS/src

# Update rosdep (ignore vicon_bridge)
RUN echo -e "# ignore the keys given in this yaml file\nyaml file://$ROSDEP_SOURCES/rosdep_ignore.yaml\n" | cat - $ROSDEP_SOURCES/20-default.list > temp && sudo mv temp $ROSDEP_SOURCES/20-default.list
RUN rosdep update

# Install dependencies in the catkin workspace
RUN $HOME/scripts/install_deps.sh $WS/src

# Initialize a catkin workspace
# NOTE: just build a simple package without a lot of dependencies
RUN cd $WS \
    && source $ROS_ROOT/setup.bash \
    && catkin build agiros_msgs

# Append to $HOME/.bashrc
RUN echo -e "\n\
source $ROS_ROOT/setup.bash\n\
source $WS/devel/setup.bash\n\n\
export ROS_MASTER_URI=http://localhost:11311\n\
alias srohmpc='tmuxinator start rohmpc'\n\
alias arohmpc='tmux a -t rohmpc'\n\
alias krohmpc='tmux kill-ses -t rohmpc'\n\n\
alias cdws='cd $WS'\n\n\
alias gen_traj='$WS/src/agiclean/scripts/generate_trajectory.sh'\n\n\
alias run_sim='roslaunch agiros agisim.launch'\n\
alias run_gazebo='roslaunch agiros simulation.launch'\n\
alias run_calib_env='roslaunch agiros mrl_falcon_calibration.launch quad_name:=falcon\$ID'\n\
alias run_calib='rosrun vicon_bridge mocap_object_calibration.py falcon\$ID calibration_board'\n\
alias run_base='roslaunch agiros mrl_base_computer_onboard.launch quad_name:=falcon\$ID'\n\
alias run_falcon='roslaunch agiros mrl_room_quadrotor_onboard.launch quad_name:=falcon\$ID'\n\
alias run_sim_1_base='roslaunch agiros main.launch interface:=simplesim mav_name:=falcon mpc_n_layers:=1 mpc_layer_idx:=0 > base.txt'\n\
alias run_sim_2_base='roslaunch agiros main.launch interface:=simplesim mav_name:=falcon mpc_n_layers:=2 mpc_layer_idx:=0 > base.txt'\n\
alias run_sim_2_1='roslaunch agiros main.launch interface:=simplesim mav_name:=falcon mpc_n_layers:=2 mpc_layer_idx:=1 > pmpc.txt'\n\
alias run_gaz_1_base='roslaunch agiros main.launch interface:=gazebo mav_name:=falcon mpc_n_layers:=1 mpc_layer_idx:=0 > base.txt'\n\
alias run_gaz_2_base='roslaunch agiros main.launch interface:=gazebo mav_name:=falcon mpc_n_layers:=2 mpc_layer_idx:=0 > base.txt'\n\
alias run_gaz_2_1='roslaunch agiros main.launch interface:=gazebo mav_name:=falcon mpc_n_layers:=2 mpc_layer_idx:=1 > pmpc.txt'\n\
" >> $HOME/.bashrc

# Start dbus when starting the container
CMD ["sudo /etc/init.d/dbus start"]
