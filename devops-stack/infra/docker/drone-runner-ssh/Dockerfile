FROM drone/drone-runner-ssh:latest

# Instalar cliente SSH e outras ferramentas úteis
RUN apk add --no-cache \
    openssh-client \
    curl \
    bind-tools \
    netcat-openbsd

# Criar diretório .ssh e configurar permissões
RUN mkdir -p /root/.ssh && \
    chmod 700 /root/.ssh