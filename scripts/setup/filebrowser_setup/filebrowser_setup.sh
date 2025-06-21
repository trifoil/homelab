#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install FileBrowser"
echo "Updating ... "
dnf update -y


prompt() {
  local prompt_message=$1
  local default_value=$2
  read -r -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

filebrowser_root_volume=$(prompt "Enter the root directory for FileBrowser to manage" "/storage")
filebrowser_config_dir=$(prompt "Enter the directory for FileBrowser config files" "/storage/filebrowser")
filebrowser_username=$(prompt "Enter your username" "admin")
filebrowser_password=$(prompt "Enter your password" "changeme")
filebrowser_port=$(prompt "Enter the port number" "8086")

# Create directory for config files if it doesn't exist
mkdir -p "$filebrowser_config_dir"


cat <<EOF > docker-compose.yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: file-manager
    volumes:
      - "$filebrowser_root_volume:/srv"
      - "$filebrowser_config_dir/database.db:/database.db"
      - "$filebrowser_config_dir/.filebrowser.json:/.filebrowser.json"
    ports:
      - "$filebrowser_port:80"
    environment:
      # These are used only on the first run to set up the admin user.
      # On subsequent runs, user management is done via the web UI.
      FB_USERNAME: "$filebrowser_username"
      FB_PASSWORD: "$filebrowser_password"
      FB_BASEURL: "/"
    restart: unless-stopped
EOF

echo "The docker-compose.yaml has been created successfully."

docker compose up -d
docker ps

read -n 1 -s -r -p "Done. Press any key to continue..."