#!/bin/bash

cd "$(dirname "$0")"

echo "This script will set up wstunnel (server or client)"
echo ""

prompt() {
  local prompt_message=$1
  local default_value=$2
  read -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

# Default storage directory
DEFAULT_STORAGE_DIR="/storage/obfuscated_wireguard_vpn"

# Ask for storage path
STORAGE_DIR=$(prompt "Enter the storage directory path" "$DEFAULT_STORAGE_DIR")

# Create storage directory
mkdir -p "$STORAGE_DIR"
echo "Using storage directory: $STORAGE_DIR"
echo ""

# Ask user if they want server or client
mode=$(prompt "Do you want to set up server or client?" "client")

if [[ "$mode" == "server" ]]; then
  echo "Setting up wstunnel server"
  
  # Server configuration
  port=$(prompt "Enter the port to expose for wstunnel" "4431")
  wireguard_port=$(prompt "Enter the WireGuard port to restrict to" "51820")
  
  cat <<EOF > docker-compose.yaml
version: '3.8'
services:
  wstunnel-server:
    image: ghcr.io/erebe/wstunnel:latest
    container_name: wstunnel-server
    command: server --restrict-to=127.0.0.1:$wireguard_port wss://0.0.0.0:$port
    ports:
      - "$port:$port"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    network_mode: host
    volumes:
      - "$STORAGE_DIR:/data"
EOF

elif [[ "$mode" == "client" ]]; then
  echo "Setting up wstunnel client"
  
  # Client configuration
  server_address=$(prompt "Enter your wstunnel server address (domain or IP)" "your-server-domain.com")
  server_port=$(prompt "Enter your wstunnel server port" "443")
  local_wireguard_port=$(prompt "Enter the local WireGuard port" "51820")
  
  cat <<EOF > docker-compose.yaml
version: '3.8'
services:
  wstunnel-client:
    image: ghcr.io/erebe/wstunnel:latest
    container_name: wstunnel-client
    command: client -L udp://$local_wireguard_port:localhost:$local_wireguard_port?timeout_sec=0 wss://$server_address:$server_port
    ports:
      - "$local_wireguard_port:$local_wireguard_port/udp"
    restart: unless-stopped
    cap_add:
      - NET_ADMIN
    network_mode: host
    volumes:
      - "$STORAGE_DIR:/data"
EOF

else
  echo "Invalid mode selected. Please choose either 'server' or 'client'."
  exit 1
fi

echo "The docker-compose.yaml has been created successfully with storage at $STORAGE_DIR."

# Start the containers
docker compose up -d
docker ps

read -n 1 -s -r -p "Done. Press any key to continue..."