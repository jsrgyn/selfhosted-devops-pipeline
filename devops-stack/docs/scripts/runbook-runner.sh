#!/bin/bash
# Uso: ./runbook-runner.sh <caminho-para-runbook.md>
set -e

RUNBOOK_FILE=$1
TEMP_SCRIPT="/tmp/runbook_script.sh"

if [ ! -f "$RUNBOOK_FILE" ]; then
  echo "Runbook não encontrado: $RUNBOOK_FILE"
  exit 1
fi

# Extrair blocos de código do runbook
awk '/^```bash/{flag=1; next} /^```/{flag=0} flag' "$RUNBOOK_FILE" > "$TEMP_SCRIPT"

echo "Executando runbook: $RUNBOOK_FILE"
echo "=================================="
bash -x "$TEMP_SCRIPT"
rm -f "$TEMP_SCRIPT"