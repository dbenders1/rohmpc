#! /bin/bash

# Define usage string
usage_str="Usage: ./docker_build.sh <imagename> (<args>) (e.g. ./docker_build.sh agi or ./docker_build.sh agi --no-cache)"

# Check if there are at least 1 argument
if [ "$#" -lt 1 ];
then
    echo "No image name provided!"
    echo $usage_str
    exit 1
else
    image_name=$1
    echo "Building Docker image $image_name"
fi

# Shift the first argument, so the rest can be provided as additional arguments to the docker build
shift 1
if [ -z "$1" ]
then
    echo "No additional arguments provided."
else
    echo "Additional arguments provided: $@"
fi

# Build the Docker image
export DOCKER_BUILDKIT=1
docker build -f Dockerfile -t $image_name $@ .
