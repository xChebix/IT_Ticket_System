#!/bin/bash

set -e

# VARIABLES

ZAMMAD_DIR="./zammad-docker-compose"
NGINX_DIR="./nginx"
BACKUP_SH="$ZAMMAD_DIR/backup.sh"

# STOPPING CONTAINERS

echo "Stopping zammad containers..."
cd $ZAMMAD_DIR
sudo docker compose down

echo "Stopping nginx container..."
cd ../$NGINX_DIR
sudo docker compose down

echo "Waiting for containers to stop..."
sleep 15


# RUNNING BACKUP

cd .. # Go back to parent folder
echo "Starting Zammad Backup..."
sudo $BACKUP_SH

# STARTING CONTAINERS

echo "Starting Zammad Containers..."
cd $ZAMMAD_DIR
sudo docker compose up -d

echo "Starting Nginx Container..."
cd ../$NGINX_DIR
sudo docker compose up -d

echo "Zammad Containers backed up successfully!!!"
