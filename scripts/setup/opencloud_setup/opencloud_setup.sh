#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install OpenCloud with external proxy support"
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
admin_password=$(prompt "Enter OpenCloud admin password" "opencloud")
volume_config=$(prompt "Enter the volume path for OpenCloud config" "/storage/opencloud/config")
volume_data=$(prompt "Enter the volume path for OpenCloud data" "/storage/opencloud/data")
volume_apps=$(prompt "Enter the volume path for OpenCloud apps" "/storage/opencloud/apps")

# Create necessary directories
echo "Creating directories..."
mkdir -p "$volume_config"
mkdir -p "$volume_data"
mkdir -p "$volume_apps"

# Create custom configuration directory
mkdir -p "$volume_config/custom"

# Create CSP configuration file
cat <<EOF > "$volume_config/csp.yaml"
default-src 'self';
script-src 'self' 'unsafe-inline' 'unsafe-eval';
style-src 'self' 'unsafe-inline';
img-src 'self' data: blob:;
font-src 'self';
connect-src 'self';
frame-src 'self';
object-src 'none';
base-uri 'self';
form-action 'self';
frame-ancestors 'self';
upgrade-insecure-requests;
EOF

# Create banned password list
cat <<EOF > "$volume_config/banned-password-list.txt
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
    container_name: OpenCloud
    image: 'opencloudeu/opencloud-rolling:latest'
    restart: always
    networks:
      opencloud-net:
    entrypoint:
      - /bin/sh
    command: ["-c", "opencloud init || true; opencloud server"]
    environment:
      OC_URL: http://localhost:9200
      OC_LOG_LEVEL: info
      OC_LOG_COLOR: "false"
      OC_LOG_PRETTY: "false"
      PROXY_TLS: "false"
      OC_INSECURE: "true"
      PROXY_ENABLE_BASIC_AUTH: "false"
      IDM_CREATE_DEMO_USERS: "false"
      IDM_ADMIN_PASSWORD: "$admin_password"
      FRONTEND_ARCHIVER_MAX_SIZE: "10000000000"
      PROXY_CSP_CONFIG_FILE_LOCATION: /etc/opencloud/csp.yaml
      OC_PASSWORD_POLICY_BANNED_PASSWORDS_LIST: banned-password-list.txt
      OC_SHARING_PUBLIC_SHARE_MUST_HAVE_PASSWORD: "true"
      OC_SHARING_PUBLIC_WRITEABLE_SHARE_MUST_HAVE_PASSWORD: "true"
      OC_PASSWORD_POLICY_DISABLED: "false"
      OC_PASSWORD_POLICY_MIN_CHARACTERS: "8"
      OC_PASSWORD_POLICY_MIN_LOWERCASE_CHARACTERS: "1"
      OC_PASSWORD_POLICY_MIN_UPPERCASE_CHARACTERS: "1"
      OC_PASSWORD_POLICY_MIN_DIGITS: "1"
      OC_PASSWORD_POLICY_MIN_SPECIAL_CHARACTERS: "1"
    volumes:
      - $volume_config/csp.yaml:/etc/opencloud/csp.yaml
      - $volume_config/banned-password-list.txt:/etc/opencloud/banned-password-list.txt
      - $volume_config:/etc/opencloud
      - $volume_data:/var/lib/opencloud
      - $volume_apps:/var/lib/opencloud/web/assets/apps
    ports:
      - '9200:9200'
    logging:
      driver: local
    privileged: true

volumes:
  opencloud-config:
  opencloud-data:

networks:
  opencloud-net:
    external: true
EOF

echo "The docker-compose.yml has been created successfully."
echo "OpenCloud configuration has been set up for external proxy deployment."

# Create the external network if it doesn't exist
docker network create opencloud-net 2>/dev/null || echo "Network opencloud-net already exists"

docker compose up -d

echo "OpenCloud is starting up..."
echo "You can access OpenCloud at http://your-server-ip:9200"
echo "Admin credentials: admin / $admin_password"
echo ""
echo "OpenCloud is configured to run behind an external proxy."
echo "Configure your reverse proxy to forward requests to port 9200."

read -n 1 -s -r -p "Done. Press any key to continue..."
