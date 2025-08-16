#!/bin/bash
BACKUP_DIR=$1
PG_BACKUP_DIR="$BACKUP_DIR/postgres"

# Parar serviços dependentes
docker stop drone-server drone-runner-ssh gitea sonarqube

# Restaurar backup base
docker run --rm -v postgres_data:/restore -v $PG_BACKUP_DIR:/backup alpine \
  sh -c "rm -rf /restore/* && tar xzf /backup/base.tar.gz -C /restore"

# Restaurar WAL logs
docker run --rm -v postgres_data:/restore/pg_wal -v $PG_BACKUP_DIR:/backup alpine \
  tar xzf /backup/pg_wal.tar.gz -C /restore/pg_wal

# Iniciar PostgreSQL
docker start postgres_dbx

# Aguardar inicialização
sleep 30

# Recriar bancos de dados
docker exec postgres_dbx psql -U $POSTGRES_USER -f /docker-entrypoint-initdb.d/01-init-databases.sql