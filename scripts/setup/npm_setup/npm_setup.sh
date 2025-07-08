#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install NGINX proxy manager with monitoring support"
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
db_mysql_password=$(prompt "Enter DB MySQL password" "npm")
db_mysql_root_password=$(prompt "Enter DB MySQL root password" "npm")
volume_data=$(prompt "Enter the volume path for NGINX Proxy Manager data" "/storage/npm/data")
volume_letsencrypt=$(prompt "Enter the volume path for Let's Encrypt" "/storage/npm/letsencrypt")
volume_mysql=$(prompt "Enter the volume path for MySQL data" "/storage/npm/mysql")
volume_logs=$(prompt "Enter the volume path for NPM logs" "/storage/npm/logs")

# Create necessary directories
echo "Creating directories..."
mkdir -p "$volume_data"
mkdir -p "$volume_letsencrypt"
mkdir -p "$volume_mysql"
mkdir -p "$volume_logs"

# Create custom configuration directory
mkdir -p "$volume_data/custom"

# Create http_top.conf with JSON log format
cat <<EOF > "$volume_data/custom/http_top.conf"
log_format json_analytics escape=json '{
       "time_local": "$time_local",
       "remote_addr": "$remote_addr",
       "request_uri": "$request_uri",
       "status": "$status",
       "server_name": "$server_name",
       "request_time": "$request_time",
       "request_method": "$request_method",
       "bytes_sent": "$bytes_sent",
       "http_host": "$http_host",
       "http_x_forwarded_for": "$http_x_forwarded_for",
       "http_cookie": "$http_cookie",
       "server_protocol": "$server_protocol",
       "upstream_addr": "$upstream_addr",
       "upstream_response_time": "$upstream_response_time",
       "ssl_protocol": "$ssl_protocol",
       "ssl_cipher": "$ssl_cipher",
       "http_user_agent": "$http_user_agent",
       "remote_user": "$remote_user"
   }';
EOF

# Create server_proxy.conf for logging configuration
cat <<EOF > "$volume_data/custom/server_proxy.conf"
access_log /data/logs/all_proxy_access.log json_analytics;
error_log /data/logs/all_proxy_error.log warn;
EOF

# Set proper permissions
chown -R 1000:1000 "$volume_data"
chown -R 1000:1000 "$volume_logs"

# Write to docker-compose.yaml
cat <<EOF > docker-compose.yaml
services:
  app:
    container_name: NGINX-proxy-manager
    image: 'jc21/nginx-proxy-manager:latest'
    restart: always
    ports:
      - '80:80' # Public HTTP Port
      - '443:443' # Public HTTPS Port
      - '81:81' # Admin Web Port
    environment:
      DB_MYSQL_HOST: "db"
      DB_MYSQL_PORT: 3306
      DB_MYSQL_USER: "npm"
      DB_MYSQL_PASSWORD: "$db_mysql_password"
      DB_MYSQL_NAME: "npm"
    volumes:
      - $volume_data:/data
      - $volume_letsencrypt:/etc/letsencrypt
      - $volume_logs:/data/logs
    depends_on:
      - db
    privileged: true

  db:
    container_name: NGINX-proxy-manager-DB
    image: 'jc21/mariadb-aria:latest'
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: "$db_mysql_root_password"
      MYSQL_DATABASE: "npm"
      MYSQL_USER: "npm"
      MYSQL_PASSWORD: "$db_mysql_password"
      MARIADB_AUTO_UPGRADE: '1'
    volumes:
      - $volume_mysql:/var/lib/mysql
    privileged: true
EOF

echo "The docker-compose.yml has been created successfully with logging support."
echo "Custom logging configuration has been set up for monitoring."

docker compose up -d

echo "NGINX Proxy Manager is starting up..."
echo "You can access the admin panel at http://your-server-ip:81"
echo "Default credentials: admin@example.com / changeme"
echo ""
echo "Logs are now being written in JSON format to: $volume_logs"
echo "These logs can be used with monitoring tools like Promtail, Loki, and Grafana."

read -n 1 -s -r -p "Done. Press any key to continue..."