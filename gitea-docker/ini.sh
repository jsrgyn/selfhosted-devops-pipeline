# Verificar configuração
docker-compose config

# Iniciar em background
#docker-compose up -d
docker-compose --env-file .env up -d

docker-compose up -d.

# Verificar logs
docker-compose logs -f