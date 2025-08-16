#!/bin/bash
BACKUP_DIR=$1

echo "Backup de metadados do Docker..."
docker inspect $(docker ps -aq) > $BACKUP_DIR/docker_containers.json
docker network ls -q | xargs docker network inspect > $BACKUP_DIR/docker_networks.json
docker volume ls -q | xargs docker volume inspect > $BACKUP_DIR/docker_volumes.json
docker image ls --format '{{.ID}}' | xargs docker image inspect > $BACKUP_DIR/docker_images.json

# Compactar metadados
tar czf $BACKUP_DIR/docker_metadata.tar.gz -C $BACKUP_DIR docker_*.json
rm $BACKUP_DIR/docker_*.json