#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install OpenCloud with Collabora integration"
echo "Updating ... "
dnf update -y

# Function to prompt user for input and set default value if input is empty
prompt() {
  local prompt_message=$1
  local default_value=$2
  read -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

# Prompt user for necessary inputs
oc_domain=$(prompt "Enter OpenCloud domain/IP" "10.10.2.115")
oc_port=$(prompt "Enter OpenCloud port" "9200")
collabora_server=$(prompt "Enter Collabora server IP" "10.10.2.115")
collabora_port=$(prompt "Enter Collabora port" "9980")
admin_password=$(prompt "Enter admin password" "admin123")
volume_config=$(prompt "Enter the volume path for OpenCloud config" "/storage/opencloud/config")
volume_data=$(prompt "Enter the volume path for OpenCloud data" "/storage/opencloud/data")
volume_apps=$(prompt "Enter the volume path for OpenCloud apps" "/storage/opencloud/apps")

# Create necessary directories
echo "Creating directories..."
mkdir -p "$volume_config"
mkdir -p "$volume_data"
mkdir -p "$volume_apps"

# Create CSP configuration
cat <<EOF > "$volume_config/csp.yaml"
# Content Security Policy configuration for OpenCloud
# This allows connections to Collabora and local network

default-src: ["'self'"]
script-src: ["'self'", "'unsafe-inline'", "'unsafe-eval'"]
style-src: ["'self'", "'unsafe-inline'"]
img-src: ["'self'", "data:", "blob:", "http:", "https:"]
font-src: ["'self'", "data:"]
connect-src: ["'self'", "ws:", "wss:", "http://$collabora_server:$collabora_port"]
frame-src: ["'self'", "http://$collabora_server:$collabora_port"]
object-src: ["'none'"]
media-src: ["'self'", "blob:"]
worker-src: ["'self'", "blob:"]
child-src: ["'self'", "blob:"]
frame-ancestors: ["'self'"]
form-action: ["'self'"]
base-uri: ["'self'"]
manifest-src: ["'self'"]
EOF

# Create banned password list
cat <<EOF > "$volume_config/banned-password-list.txt"
password
123456
123456789
qwerty
abc123
password123
admin
root
user
test
EOF

# Set proper permissions
chown -R 1000:1000 "$volume_config"
chown -R 1000:1000 "$volume_data"
chown -R 1000:1000 "$volume_apps"

# Write to docker-compose.yaml
cat <<EOF > docker-compose.yaml
services:
  opencloud:
    container_name: opencloud
    image: 'opencloudeu/opencloud-rolling:latest'
    restart: always
    ports:
      - '127.0.0.1:$oc_port:$oc_port'
    environment:
      # Basic configuration
      OC_URL: http://$oc_domain:$oc_port
      OC_LOG_LEVEL: info
      OC_LOG_COLOR: "false"
      OC_LOG_PRETTY: "false"
      
      # Security settings for reverse proxy setup
      PROXY_TLS: "false"
      OC_INSECURE: "true"
      PROXY_ENABLE_BASIC_AUTH: "false"
      
      # Admin and user settings
      IDM_CREATE_DEMO_USERS: "false"
      IDM_ADMIN_PASSWORD: "$admin_password"
      
      # Collabora integration
      COLLABORA_SERVER: $collabora_server
      COLLABORA_PORT: $collabora_port
      COLLABORA_URL: http://$collabora_server:$collabora_port
      
      # Additional services
      OC_ADD_RUN_SERVICES: notifications,collabora
      
      # File size limits
      FRONTEND_ARCHIVER_MAX_SIZE: "10000000000"
      
      # CSP configuration
      PROXY_CSP_CONFIG_FILE_LOCATION: /etc/opencloud/csp.yaml
      
      # Password policy
      OC_PASSWORD_POLICY_BANNED_PASSWORDS_LIST: banned-password-list.txt
      OC_SHARING_PUBLIC_SHARE_MUST_HAVE_PASSWORD: "true"
      OC_SHARING_PUBLIC_WRITEABLE_SHARE_MUST_HAVE_PASSWORD: "true"
      OC_PASSWORD_POLICY_DISABLED: "false"
      OC_PASSWORD_POLICY_MIN_CHARACTERS: "8"
      OC_PASSWORD_POLICY_MIN_LOWERCASE_CHARACTERS: "1"
      OC_PASSWORD_POLICY_MIN_UPPERCASE_CHARACTERS: "1"
      OC_PASSWORD_POLICY_MIN_DIGITS: "1"
      OC_PASSWORD_POLICY_MIN_SPECIAL_CHARACTERS: "1"
      
      # Timezone
      TZ: \$(timedatectl show --property=Timezone --value 2>/dev/null || echo "UTC")
      
      # User/Group IDs
      PUID: 1000
      PGID: 1000
      
    volumes:
      - $volume_config/csp.yaml:/etc/opencloud/csp.yaml
      - $volume_config/banned-password-list.txt:/etc/opencloud/banned-password-list.txt
      - $volume_config:/etc/opencloud
      - $volume_data:/var/lib/opencloud
      - $volume_apps:/var/lib/opencloud/web/assets/apps
    entrypoint:
      - /bin/sh
    command: ["-c", "opencloud init --insecure true || true; opencloud server"]
    privileged: true
EOF

echo "The docker-compose.yml has been created successfully with Collabora integration."
echo "OpenCloud is configured to work behind a reverse proxy without SSL certificates."

docker compose up -d

echo "OpenCloud is starting up..."
echo "You can access OpenCloud at http://$oc_domain:$oc_port"
echo "Default credentials: admin / $admin_password"
echo ""
echo "Collabora integration is configured at: http://$collabora_server:$collabora_port"
echo "Make sure your Collabora server is running and accessible."
echo ""
echo "For reverse proxy setup, configure your proxy to forward:"
echo "  - $oc_domain -> 127.0.0.1:$oc_port"
echo "  - $oc_domain/collabora -> $collabora_server:$collabora_port"

read -n 1 -s -r -p "Done. Press any key to continue..."
