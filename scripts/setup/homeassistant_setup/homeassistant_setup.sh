#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install Home Assistant"
echo "Updating ... "
dnf update -y

prompt() {
  local prompt_message=$1
  local default_value=$2
  read -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

config_path=$(prompt "Enter the path for Home Assistant config files" "/storage/homeassistant/config")
timezone=$(prompt "Enter your timezone (e.g. America/New_York)" "$(timedatectl | grep "Time zone" | awk '{print $3}')")

cat <<EOF > docker-compose.yaml
services:
  homeassistant:
    container_name: homeassistant
    image: "ghcr.io/home-assistant/home-assistant:stable"
    volumes:
      - $config_path:/config
      - /etc/localtime:/etc/localtime:ro
      - /run/dbus:/run/dbus:ro
    ports:
      - "8123:8123"  # Maps host port 8123 to container port 8123
    restart: unless-stopped
    privileged: true
EOF

echo "The docker-compose.yaml has been created successfully."

docker compose up -d
docker ps

read -n 1 -s -r -p "Done. Press any key to continue..."