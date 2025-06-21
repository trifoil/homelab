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

storage_path=$(prompt "Enter the storage path for FileBrowser" "/storage/filebrowser")
port=$(prompt "Enter the port number for FileBrowser" "8086")

# Create directories and empty config files to ensure correct permissions and existence
mkdir -p "$storage_path/srv"
touch "$storage_path/filebrowser.db"
touch "$storage_path/filebrowser.json"

cat <<EOF > docker-compose.yaml
services:
  filebrowser:
    image: filebrowser/filebrowser
    container_name: filebrowser
    user: "1000:1000"
    ports:
      - "$port:80"
    volumes:
      - "$storage_path/srv:/srv"
      - "$storage_path/filebrowser.db:/database.db"
      - "$storage_path/filebrowser.json:/.filebrowser.json"
    restart: always
EOF

echo "The docker-compose.yaml has been created successfully."
echo "Default credentials are admin / admin. Please change them on first login."

docker compose up -d
docker ps

read -n 1 -s -r -p "Done. Press any key to continue..."