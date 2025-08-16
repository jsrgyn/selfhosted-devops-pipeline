#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/automated/postgres"
mkdir -p $BACKUP_DIR

echo "[$(date)] Iniciando backup do PostgreSQL"
docker exec postgres_dbx pg_dumpall -U ${POSTGRES_USER} | gzip > $BACKUP_DIR/postgres_$DATE.sql.gz

# Verificar integridade
if gzip -t $BACKUP_DIR/postgres_$DATE.sql.gz; then
  echo "Backup PostgreSQL válido: $BACKUP_DIR/postgres_$DATE.sql.gz"
else
  echo "ERRO: Backup PostgreSQL corrompido!"
  rm $BACKUP_DIR/postgres_$DATE.sql.gz
  exit 1
fi