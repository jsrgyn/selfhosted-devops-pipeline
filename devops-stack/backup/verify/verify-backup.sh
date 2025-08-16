#!/bin/bash
BACKUP_DIR=$1

# Verificar arquivos essenciais
declare -a ESSENTIAL_FILES=(
  "postgres/base.tar.gz"
  "gitea/backup.tar.gz"
  "docker_metadata.tar.gz"
)

for file in "${ESSENTIAL_FILES[@]}"; do
  if [ ! -f "$BACKUP_DIR/$file" ]; then
    echo "ERRO: Arquivo essencial faltando: $file"
    exit 1
  fi
done

# Testar integridade dos arquivos
gzip -t $BACKUP_DIR/postgres/base.tar.gz || exit 1
tar -tzf $BACKUP_DIR/docker_metadata.tar.gz >/dev/null || exit 1

echo "Verificação de backup bem-sucedida!"