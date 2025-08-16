#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backup/automated/sonarqube"
mkdir -p $BACKUP_DIR

echo "[$(date)] Iniciando backup do SonarQube"
docker exec sonarqube tar czf - -C /opt/sonarqube/data . > $BACKUP_DIR/sonarqube_$DATE.tar.gz

# Verificar integridade
if tar -tzf $BACKUP_DIR/sonarqube_$DATE.tar.gz >/dev/null; then
  echo "Backup SonarQube válido: $BACKUP_DIR/sonarqube_$DATE.tar.gz"
else
  echo "ERRO: Backup SonarQube corrompido!"
  rm $BACKUP_DIR/sonarqube_$DATE.tar.gz
  exit 1
fi