#!/bin/bash
echo "Iniciando Gitea..."
#docker-compose up -d
docker-compose --env-file .env up -d
echo "Gitea iniciado! Acesse: http://localhost:3000"