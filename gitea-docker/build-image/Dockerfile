# ==============================================================================
# Dockerfile para Servidor de Build ARM64 com ferramentas de rede, monitoramento e build
# ==============================================================================

FROM --platform=linux/arm64 ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive

# ==============================================================================
# Instala pacotes essenciais de sistema, rede e monitoramento
# ==============================================================================
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    sudo \
    jq \
    git \
    curl \
    ca-certificates \
    apt-utils \
    openjdk-17-jre \
    wget \
    unzip \
    htop \
    iputils-ping \
    net-tools \
    dnsutils \
    lsof \
    # --- NOVO ---
    build-essential \                # G++/make para compilar pacotes nativos (útil para Node addons)
    python3 \                        # Alguns pacotes de Node.js precisam disso em ambiente de CI
    python3-pip \                    # Para instalar ferramentas auxiliares como httpie
    netcat \                         # Testes de portas e conexões
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ==============================================================================
# Instala Node.js 18 + Yarn
# ==============================================================================
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# ==============================================================================
# Instala o SonarScanner via NPM (compatível com ARM64)
# ==============================================================================
RUN npm install -g sonarqube-scanner

# ==============================================================================
# Instala o PM2 globalmente
# ==============================================================================
RUN npm install -g pm2

# ==============================================================================
# (Opcional) Instala ferramentas extras úteis para troubleshooting e CI/CD
# ==============================================================================
# --- NOVO ---
RUN npm install -g serve concurrently \
    && pip install httpie \
    && echo 'alias ll="ls -alF"' >> /root/.bashrc \
    && echo 'alias ..="cd .."' >> /root/.bashrc

# ==============================================================================
# Configura SSH
# ==============================================================================
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/root:\*:/root::/' /etc/shadow \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    && mkdir -p /run/sshd \
    && mkdir -p /home/ubuntu/builds \
    && mkdir -p /root/.ssh && chmod 700 /root/.ssh

# ==============================================================================
# Adiciona um usuário não-root com permissão de sudo (opcional e seguro)
# ==============================================================================
# --- NOVO ---
RUN useradd -m -s /bin/bash builder \
    && echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && mkdir -p /home/builder/.ssh && chmod 700 /home/builder/.ssh

# Copiar a chave pública manualmente no runtime:
# docker run -v ./ssh/id_rsa.pub:/root/.ssh/authorized_keys

# ==============================================================================
# Expõe as portas necessárias
# ==============================================================================
EXPOSE 22     # Acesso SSH
EXPOSE 8000   # Porta da aplicação Node.js

# ==============================================================================
# Comando de inicialização padrão
# ==============================================================================
CMD ["/usr/sbin/sshd", "-D"]