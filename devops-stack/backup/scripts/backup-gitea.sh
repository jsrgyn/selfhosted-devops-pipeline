#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/automated/gitea"
mkdir -p $BACKUP_DIR

echo "[$(date)] Iniciando backup do Gitea"
docker exec gitea tar czf - -C /data . > $BACKUP_DIR/gitea_$DATE.tar.gz

# Verificar integridade
if tar -tzf $BACKUP_DIR/gitea_$DATE.tar.gz >/dev/null; then
  echo "Backup Gitea válido: $BACKUP_DIR/gitea_$DATE.tar.gz"
else
  echo "ERRO: Backup Gitea corrompido!"
  rm $BACKUP_DIR/gitea_$DATE.tar.gz
  exit 1
fi