#!/bin/bash
echo "==== INÍCIO DO BACKUP COMPLETO ===="
/backup/scripts/backup-postgres.sh
/backup/scripts/backup-gitea.sh
/backup/scripts/backup-sonarqube.sh

# Sincronizar com armazenamento remoto (opcional)
# aws s3 sync /backup/automated s3://seu-bucket/backups/

echo "==== BACKUP COMPLETO COM SUCESSO ===="