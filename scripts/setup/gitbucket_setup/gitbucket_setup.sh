#!/bin/bash

cd "$(dirname "$0")"

echo "The script will now install gitbucket"
echo "Updating ... "
dnf update -y

prompt() {
  local prompt_message=$1
  local default_value=$2
  read -p "$prompt_message [$default_value]: " input
  echo "${input:-$default_value}"
}

db_root_password=$(prompt "Enter the root password for the GitBucket database" "changeme")
db_name=$(prompt "Enter the name for the GitBucket database" "gitbucket")
db_user=$(prompt "Enter the user for the GitBucket database" "gitbucket")
db_password=$(prompt "Enter the password for the GitBucket database" "changeme")
storage_repositories=$(prompt "Enter the storage path for GitBucket repositories" "/storage/gitbucket/repositories")
storage_data=$(prompt "Enter the storage path for GitBucket data" "/storage/gitbucket/data")
storage_gist=$(prompt "Enter the storage path for GitBucket gist" "/storage/gitbucket/gist")
storage_plugins=$(prompt "Enter the storage path for GitBucket plugins" "/storage/gitbucket/plugins")
storage_backup=$(prompt "Enter the storage path for GitBucket backup" "/storage/gitbucket/backup")
storage_conf_gitbucket=$(prompt "Enter the storage path for GitBucket gitbucket.conf" "/storage/gitbucket/conf/gitbucket.conf")
storage_conf_backup=$(prompt "Enter the storage path for GitBucket backup.conf" "/storage/gitbucket/conf/backup.conf")
storage_conf_mysql=$(prompt "Enter the storage path for GitBucket mysql config" "/storage/gitbucket/conf/mysql")
storage_mysql_volume=$(prompt "Enter the storage path for GitBucket mysql volume" "/storage/gitbucket/mysql")

cat <<EOF > docker-compose.yaml
services:
    main-gitbucket:
      image: pgollor/gitbucket:latest
      mem_limit: 2g
      restart: always
      depends_on:
        mysql-gitbucket:
          condition: service_healthy
      environment:
        - GITBUCKET_USER_ID=\${GITBUCKET_USER_ID:-9000}
        - GITBUCKET_DATABASE_HOST=database
        - GITBUCKET_DATABASE_NAME=${db_name}
        - GITBUCKET_DATABASE_USER=${db_user}
        - GITBUCKET_DATABASE_PASSWORD=${db_password}
        - GITBUCKET_MAX_FILE_SIZE=\${GITBUCKET_MAX_FILE_SIZE:-10485760}
        - TZ=\${TZ}
      volumes:
        - ${storage_repositories}:/srv/gitbucket/repositories/
        - ${storage_data}:/srv/gitbucket/data/
        - ${storage_gist}:/srv/gitbucket/gist/
        - ${storage_plugins}:/srv/gitbucket/plugins/
        - ${storage_backup}:/srv/gitbucket/backup/
        - ${storage_conf_gitbucket}:/srv/gitbucket/gitbucket.conf
        - ${storage_conf_backup}:/srv/gitbucket/backup.conf
      tmpfs:
        - /tmp
      ports:
        - "${GITBUCKET_WEB_BIND:-127.0.0.1}:${GITBUCKET_WEB_PORT:-8080}:8080"
        - "${GITBUCKET_SSH_BIND:-127.0.0.1}:${GITBUCKET_SSH_PORT:-29418}:29418"
      links:
        - mysql-gitbucket:database

    mysql-gitbucket:
      image: mariadb:10.3
      mem_limit: 1g
      restart: always
      command: mysqld --skip-name-resolve --skip-host-cache --log-warnings=0
      healthcheck:
        test: ["CMD", "mysqladmin", "-u$GITBUCKET_DATABASE_USER", "-p$GITBUCKET_DATABASE_PASSWORD",  "ping", "-h", "localhost"]
        interval: 30s
        timeout: 30s
        retries: 10
      environment:
        - MYSQL_ROOT_PASSWORD=${db_root_password}
        - MYSQL_DATABASE=${db_name}
        - MYSQL_USER=${db_user}
        - MYSQL_PASSWORD=${db_password}
      volumes:
        - mysql-vol-1:/var/lib/mysql/
        - ${storage_conf_mysql}:/etc/mysql/conf.d/:ro

volumes:
  mysql-vol-1:

EOF

echo "The docker-compose.yaml has been created successfully."

docker compose up -d
docker ps

read -n 1 -s -r -p "Done. Press any key to continue..."