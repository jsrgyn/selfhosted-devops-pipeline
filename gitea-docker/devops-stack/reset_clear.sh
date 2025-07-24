#!/bin/bash

docker-compose down -v
docker volume prune -f
docker volume ls
docker-compose down --volumes --remove-orphans
./clear_data.sh
chmod +x config/postgres/init-scripts/01-init-databases.sh
docker-compose --env-file .env up -d --build --force-recreate