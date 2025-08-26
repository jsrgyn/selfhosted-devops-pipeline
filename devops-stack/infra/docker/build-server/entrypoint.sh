#!/bin/bash
set -e

# Garantir que diretórios existam
mkdir -p /run/sshd /root/.ssh
chmod 700 /root/.ssh

# Configurar authorized_keys se existir
if [ -f /root/.ssh/authorized_keys ]; then
    chmod 600 /root/.ssh/authorized_keys
    chown root:root /root/.ssh/authorized_keys
fi

# Iniciar SSH
echo "Iniciando servidor SSH na porta 22..."
exec /usr/sbin/sshd -D -e -p 22