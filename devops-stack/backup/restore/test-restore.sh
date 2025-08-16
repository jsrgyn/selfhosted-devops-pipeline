#!/bin/bash
# Simular perda de dados
docker-compose stop postgres_dbx gitea sonarqube
docker volume rm devops-stack_postgres_data devops-stack_gitea_data

# Restaurar backup mais recente
LATEST_BACKUP=$(ls -td /backup/automated/* | head -1)

# Restaurar PostgreSQL
gunzip < $LATEST_BACKUP/postgres_*.sql.gz | docker-compose exec -T postgres_dbx psql -U ${POSTGRES_USER}

# Restaurar Gitea
tar -xzf $LATEST_BACKUP/gitea_*.tar.gz -C ./data/gitea

# Restaurar SonarQube
tar -xzf $LATEST_BACKUP/sonarqube_*.tar.gz -C ./data/sonarqube/data

# Reiniciar serviços
docker-compose up -d

# Executar teste de saúde
./health-check.sh