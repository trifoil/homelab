#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install Nextloud AIO"
echo "Updating ... "
dnf update -y

# Default values
DEFAULT_VOLUME_LOCATION="/storage/aio"
DEFAULT_PASSWORD="changeme"

# Read input variables
#read -p "Enter the proxy IP address : " IP_ADDRESS
#read -p "Enter the domain name : " DOMAIN
read -p "Enter the volume location [default: $DEFAULT_VOLUME_LOCATION]: " VOLUME_LOCATION
read -p "Enter the admin password [default: $DEFAULT_PASSWORD]: " ADMIN_PASSWORD

# Use default values if inputs are empty
VOLUME_LOCATION=${VOLUME_LOCATION:-$DEFAULT_VOLUME_LOCATION}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-$DEFAULT_PASSWORD}

# Generate the docker-compose.yaml file
cat <<EOF > docker-compose.yaml
services:
  nextcloud-aio-mastercontainer:
    image: nextcloud/all-in-one:latest
    init: true
    restart: always
    container_name: nextcloud-aio-mastercontainer 
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config 
      - /var/run/docker.sock:/var/run/docker.sock:ro 
    network_mode: bridge 
    ports:
      - 8080:8080
    environment:
      NEXTCLOUD_DATADIR: ${VOLUME_LOCATION} 
      APACHE_PORT: 11000
      APACHE_IP_BINDING: 0.0.0.0
      NEXTCLOUD_UPLOAD_LIMIT: 50G
volumes: 
  nextcloud_aio_mastercontainer:
    name: nextcloud_aio_mastercontainer 
EOF

echo "The docker-compose.yaml has been created successfully."

docker compose up -d
docker ps

read -n 1 -s -r -p "Done. Press any key to continue..."