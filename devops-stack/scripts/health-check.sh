#!/bin/bash
set -e

echo "=== TESTE DE SAÚDE DO AMBIENTE DEVOPS ==="

# Testar Gitea
echo "Verificando Gitea..."
docker-compose exec gitea curl -X POST http://localhost:3000/user/login \
  -d "user_name=admin&password=${GITEA_ADMIN_PASSWORD}" | grep 'Logged in successfully'

# Testar Drone
echo "Verificando Drone..."
docker-compose exec drone-server curl -f http://localhost:80/healthz

# Testar SonarQube
echo "Verificando SonarQube..."
docker-compose exec sonarqube curl -f http://localhost:9000/api/system/status

echo "=== TODOS OS TESTES PASSARAM COM SUCESSO ==="