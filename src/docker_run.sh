#!/bin/bash

# Define usage string
usage_str="Usage: ./docker_run.sh <imagename> <falcon_id> <yourname-yourproject-youralgorithm> (e.g. ./docker_run.sh agi 0 johndoe-paper-rohmpc)"

# Process input arguments
if [ -z "$1" ]
then
    echo "No image name provided!"
    echo $usage_str
    exit 1
else
    image_name=$1
fi

if [ -z "$2" ]
then
    echo "No Falcon ID provided!"
    echo "Usage: ./run_docker.sh <falcon_id> <yourname-yourproject-youralgorithm> (e.g. ./run_docker.sh 1 johndoe-demo-mpc)"
    exit 1
else
    falcon_id=$2
fi

if [ -z "$3" ]
then
    echo "No container name provided!"
    echo $usage_str
    exit 1
else
    container_name=$3
fi

echo "Starting Docker container $container_name from image $image_name with falcon ID $falcon_id"

# Set authentication for X server
XAUTH_HOST_DIR=~/.docker
XAUTH_CONTAINER_DIR=/tmp
XAUTH_FILE_NAME=.docker.xauth
XAUTH_HOST=$XAUTH_HOST_DIR/$XAUTH_FILE_NAME
XAUTH_CONTAINER=$XAUTH_CONTAINER_DIR/$XAUTH_FILE_NAME
if [ ! -f $XAUTH_HOST ]
then
    echo "No file named $XAUTH_FILE_NAME found in $XAUTH_HOST_DIR. Creating $XAUTH_HOST"
    cd $XAUTH_HOST_DIR
    sudo touch $XAUTH_FILE_NAME
fi
xauth nlist $DISPLAY | sed -e 's/^..../ffff/' | sudo xauth -f $XAUTH_HOST nmerge -

# Run the Docker container
# Check NVIDIA GPU Docker support
# More info: http://wiki.ros.org/docker/Tutorials/Hardware%20Acceleration
NVIDIA_DOCKER_REQUIREMENT='nvidia-docker2'
GPU_OPTIONS=""
if dpkg --get-selections | grep -q "^$NVIDIA_DOCKER_REQUIREMENT[[:space:]]*install$" >/dev/null;
then
  echo "Adding NVIDIA support to $container_name"
  GPU_OPTIONS="--gpus all --runtime=nvidia"
  docker run \
    -e "DISPLAY=$DISPLAY" \
    -e "TERM=xterm-256color" \
    -e "ID=$falcon_id" \
    ${GPU_OPTIONS} \
    -it \
    --name $container_name \
    --network="host" \
    --privileged \
    -v "./catkin_ws/src:/home/agilicious/catkin_ws/src:rw" \
    $image_name \
    bash
else
  echo "No NVIDIA support found. Running $container_name without GPU support"
  docker run \
    -e "DISPLAY=$DISPLAY" \
    -e "TERM=xterm-256color" \
    -e "ID=$falcon_id" \
    -it \
    --name $container_name \
    --network="host" \
    --privileged \
    -v "./catkin_ws/src:/home/agilicious/catkin_ws/src:rw" \
    $image_name \
    bash
fi
