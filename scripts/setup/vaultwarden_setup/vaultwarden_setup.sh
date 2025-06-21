#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install Vaultwarden"

# Function to prompt for input with a default value
prompt() {
    local prompt_message=$1
    local default_value=$2
    read -p "$prompt_message [$default_value]: " input
    echo "${input:-$default_value}"
}

# Prompt for user-defined values
DOMAIN=$(prompt "Enter the domain for Vaultwarden" "https://vaultwarden.example.com")
PORT=$(prompt "Enter the port for Vaultwarden" "8081")
DATA_PATH=$(prompt "Enter the path for Vaultwarden data" "/storage/vaultwarden")

# Create the data directory if it doesn't exist
mkdir -p "$DATA_PATH"

# Create docker-compose.yaml
cat <<EOF > docker-compose.yaml
services:
  vaultwarden:
    image: vaultwarden/server:latest
    container_name: vaultwarden
    restart: unless-stopped
    environment:
      DOMAIN: "$DOMAIN"
    volumes:
      - "$DATA_PATH:/data/"
    ports:
      - "$PORT:80"
EOF

echo "The docker-compose.yaml has been created successfully."

docker compose up -d
docker ps

read -n 1 -s -r -p "Done. Press any key to continue..."

