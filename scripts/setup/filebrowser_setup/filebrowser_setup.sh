#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install FileBrowser"
echo "Updating ... "
dnf update -y


prompt() {
  local prompt_message=$1
  local default_value=$2
  read -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

filebrowser_volume=$(prompt "Enter the volume to be browsed" "/storage")
filebrowser_username=$(prompt "Enter your username" "admin")
filebrowser_password=$(prompt "Enter your password" "changeme")
filebrowser_port=$(prompt "Enter the port number" "8086")


cat <<EOF > docker-compose.yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: file-manager
    volumes:
      - $filebrowser_volume:/srv
    ports:
      - "$filebrowser_port:80"
    environment:
      FB_BASEURL: "/"
    restart: unless-stopped
EOF

echo "The docker-compose.yaml has been created successfully."

docker compose up -d
docker ps

read -n 1 -s -r -p "Done. Press any key to continue..."