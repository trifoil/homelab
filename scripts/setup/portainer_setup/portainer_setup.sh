#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install Portainer"
echo "Updating ... "
dnf update -y

# Function to prompt for user input with a default value
prompt_with_default() {
    local prompt_message=$1
    local default_value=$2
    read -p "$prompt_message [$default_value]: " input
    echo "${input:-$default_value}"
}

# Prompt user for Portainer password and storage path
PORTAINER_PASSWORD=$(prompt_with_default "Enter Portainer password" "default_password")
STORAGE_PATH=$(prompt_with_default "Enter storage path" "/storage/portainer")

# Pull and run the Portainer image with privileged mode due to SELinux conflicts
docker volume create portainer_data
docker run -d --privileged -p 9443:9443 -p 8000:8000 --name portainer --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v $STORAGE_PATH/data:/data \
    portainer/portainer-ce:latest

# Pull and run the Watchtower image for automated updates
docker run --detach \
    --privileged \
    --name watchtower \
    --restart always \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    containrrr/watchtower

# Display Docker version
docker --version

echo "Portainer is running and accessible at https://localhost:9443"
echo "Default storage path is set to $STORAGE_PATH"


read -n 1 -s -r -p "Done. Press any key to continue..."