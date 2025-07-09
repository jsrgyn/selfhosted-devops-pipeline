#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup do banco de dados
docker-compose exec -T db pg_dump -U gitea gitea > "$BACKUP_DIR/gitea_db_$DATE.sql"

# Backup dos dados
tar -czf "$BACKUP_DIR/gitea_data_$DATE.tar.gz" data/

echo "Backup criado: $DATE"