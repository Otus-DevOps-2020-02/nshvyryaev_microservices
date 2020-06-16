#!/bin/bash
set -ex

DOCKER_MACHINE_NAME=gitlab-ci

# Create necessary directories
docker-machine ssh ${DOCKER_MACHINE_NAME} "sudo mkdir -p /srv/gitlab/config /srv/gitlab/data /srv/gitlab/logs"
docker-machine ssh ${DOCKER_MACHINE_NAME} "sudo chown -R docker-user:docker-user /srv/gitlab"

# Use docker-machine
eval "$(docker-machine env ${DOCKER_MACHINE_NAME})"

# Get ip of gitlab instance
export DOCKER_IP=$(docker-machine ip ${DOCKER_MACHINE_NAME})

cd ..
docker-compose up -d
