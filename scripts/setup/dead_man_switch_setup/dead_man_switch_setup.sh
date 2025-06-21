#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install the dead man's switch"
echo "Updating ... "
dnf update -y

prompt() {
  local prompt_message=$1
  local default_value=$2
  read -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

volume_data=$(prompt "Enter the volume for the dead man's switch" "/storage/deadmanswitch")
port=$(prompt "Enter the port number" "3000")
mail_username=$(prompt "Enter your mail" "your-gmail-email@gmail.com")
mail_password=$(prompt "Enter the mail password" "your-gmail-password")
smtp_server=$(prompt "Enter the smtp server" "smtp.gmail.com")
smtp_port=$(prompt "Enter the smtp port" "465")
message=$(prompt "Enter your message" "If you read this, I have not touched the server for a month")
web_password=$(prompt "Enter the webUI password" "password")
recipient=$(prompt "Enter the recipient mail" "recipient@example.com")

# Ensure the directory exists
mkdir -p "$volume_data"

# Create the config.toml file
config_file="$volume_data/config.toml"
cat <<EOF >"$config_file"
# Template config file for the Dead Man's Switch.
# https://github.com/storopoli/dead-man-switch

username = "$mail_username"
password = "$mail_password"
smtp_server = "$smtp_server"
smtp_port = $smtp_port
message = "I'm probably dead, go to Central Park NY under bench #137 you'll find an age-encrypted drive. Password is our favorite music in Pascal case."
message_warning = "Hey, you haven't checked in for a while. Are you okay?"
subject = "[URGENT] Something Happened to Me!"
subject_warning = "[URGENT] You need to check in!"
to = "$recipient"
from = "$mail_username"
# attachment = "/root/important_file.gpg"   # optional
timer_warning = 120
timer_dead_man = 120
web_password = "$web_password"
EOF

# Create the docker-compose.yaml file
compose_file="docker-compose.yaml"
cat <<EOF >"$compose_file"
services:
  dead_man_switch:
    image: ghcr.io/storopoli/dead_man_switch:latest
    ports:
      - "$port:3000"
    volumes:
      - $config_file:/root/.config/deadman/config.toml
EOF

# Start the Docker Compose service
docker compose up -d

read -n 1 -s -r -p "Done. Press any key to continue..."
