#!/bin/bash
BACKUP_DIR=$1

# Restaurar metadados
tar xzf $BACKUP_DIR/docker_metadata.tar.gz -C /tmp
docker network create --subnet=172.20.0.0/16 devops-network

# Restaurar volumes
/restore/restore-volumes.sh $BACKUP_DIR

# Restaurar PostgreSQL
/restore/restore-postgres.sh $BACKUP_DIR

# Restaurar outros serviços
docker-compose up -d