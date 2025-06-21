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

filebrowser_volume=$(prompt "Enter the volume to be browsed" "/storage")
filebrowser_database_path=$(prompt "Enter the path for the FileBrowser database file" "/storage/filebrowser/database.db")
filebrowser_settings_path=$(prompt "Enter the path for the FileBrowser settings file" "/storage/filebrowser/.filebrowser.json")
filebrowser_username=$(prompt "Enter your username" "admin")
filebrowser_password=$(prompt "Enter your password" "changeme")
filebrowser_port=$(prompt "Enter the port number" "8086")

# Create directory for database and settings if it doesn't exist
mkdir -p "$(dirname "$filebrowser_database_path")"
mkdir -p "$(dirname "$filebrowser_settings_path")"
touch "$filebrowser_database_path"
touch "$filebrowser_settings_path"


cat <<EOF > docker-compose.yaml
services:
  filebrowser:
    image: filebrowser/filebrowser:latest
    container_name: file-manager
    user: "$(id -u):$(id -g)"
    volumes:
      - "$filebrowser_volume:/srv"
      - "$filebrowser_database_path:/database.db"
      - "$filebrowser_settings_path:/.filebrowser.json"
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