#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now set up a static website server"
echo "Updating ... "
dnf update -y

prompt() {
  local prompt_message=$1
  local default_value=$2
  read -r -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

website_name=$(prompt "Enter the container name for the website" "static-website")
storage_path=$(prompt "Enter the storage path for your website files" "/storage/static-website")
port=$(prompt "Enter the port number" "8082")

# Create the storage directory and a default index.html file
mkdir -p "$storage_path"
cat <<EOF > "$storage_path/index.html"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding-top: 5em; }
    </style>
</head>
<body>
    <h1>It works!</h1>
    <p>Your static website is running.</p>
    <p>You can now add your own HTML/CSS files to the <code>$storage_path</code> directory.</p>
</body>
</html>
EOF

cat <<EOF > docker-compose.yaml
services:
  web:
    image: nginx:alpine
    container_name: $website_name
    ports:
      - "$port:80"
    volumes:
      - $storage_path:/usr/share/nginx/html:ro
    restart: always

EOF

echo "The docker-compose.yaml has been created successfully."

docker compose up -d
docker ps

read -n 1 -s -r -p "Done. Press any key to continue..." 