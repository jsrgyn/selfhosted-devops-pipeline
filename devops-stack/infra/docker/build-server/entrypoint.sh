#!/bin/bash
set -e

# Garantir que diretórios existam
mkdir -p /run/sshd /root/.ssh
chmod 700 /root/.ssh

# Ajustar permissões do authorized_keys montado
if [ -f /root/.ssh/authorized_keys ]; then
    chmod 600 /root/.ssh/authorized_keys
    echo "authorized_keys encontrado e permissões ajustadas."
else
    echo "⚠️ Nenhum authorized_keys encontrado em /root/.ssh/"
fi

# Gerar chaves host se não existirem
if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
    ssh-keygen -A
fi

# Iniciar SSH
echo "Iniciando servidor SSH na porta 2222..."
exec /usr/sbin/sshd -D -e -p 2222