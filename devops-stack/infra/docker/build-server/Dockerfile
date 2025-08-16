# ==============================================================================
# Dockerfile para Servidor de Build ARM64 com ferramentas de rede, monitoramento e build
# Local: infra/docker/build-server/Dockerfile
# ==============================================================================

# ==============================================================================
# Dockerfile para Servidor de Build ARM64
# ==============================================================================

FROM --platform=linux/arm64 ubuntu:jammy

LABEL maintainer="Sr. Johnathan - devops-stack"
LABEL description="Imagem customizada para runner SSH Drone CI em arquitetura ARM64"

ENV DEBIAN_FRONTEND=noninteractive

# Instala pacotes essenciais
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server sudo jq git curl ca-certificates apt-utils openjdk-17-jre \
    wget unzip htop iputils-ping net-tools dnsutils lsof build-essential \
    python3 python3-pip netcat mysql-client diffutils vim sed grep \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Node.js + Yarn
ARG NODE_VERSION=18
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# SonarScanner
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-5.0.1.3006-linux.zip \
    && unzip sonar-scanner-cli-5.0.1.3006-linux.zip -d /opt \
    && ln -s /opt/sonar-scanner-*/bin/sonar-scanner /usr/local/bin/sonar-scanner \
    && rm sonar-scanner-cli-5.0.1.3006-linux.zip

# PM2 + extras
RUN npm install -g pm2 serve concurrently \
    && pip install httpie \
    && echo 'alias ll="ls -alF"' >> /root/.bashrc \
    && echo 'alias ..="cd .."' >> /root/.bashrc

# Instalar ferramentas de segurança - trivy
RUN apt-get update && \
    apt-get install -y wget apt-transport-https gnupg lsb-release && \
    wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor -o /usr/share/keyrings/trivy.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | tee -a /etc/apt/sources.list.d/trivy.list && \
    apt-get update && \
    apt-get install -y trivy

# Instalar OWASP Dependency-Check
ENV DC_VERSION=8.4.0
RUN wget https://github.com/jeremylong/DependencyCheck/releases/download/v${DC_VERSION}/dependency-check-${DC_VERSION}-release.zip \
    && unzip dependency-check-${DC_VERSION}-release.zip -d /opt \
    && rm dependency-check-${DC_VERSION}-release.zip \
    && ln -s /opt/dependency-check/bin/dependency-check.sh /usr/local/bin/dependency-check

# Adicionar após as instalações de segurança:
# Dependências para Cypress
RUN apt-get update && apt-get install -y \
    libgtk2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libnotify-dev \
    libgconf-2-4 \
    libnss3 \
    libxss1 \
    libasound2 \
    libxtst6 \
    xauth \
    xvfb

# Configurar SSH e criar usuário builder
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/root:\*:/root::/' /etc/shadow \
    && sed -i 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd \
    && mkdir -p /run/sshd /root/.ssh \
    && chmod 700 /root/.ssh \
    && useradd -m -s /bin/bash builder \
    && echo 'builder ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers \
    && mkdir -p /home/builder/.ssh \
    && chmod 700 /home/builder/.ssh \
    && echo 'alias ll="ls -alF"' >> /etc/bash.bashrc \
    && echo 'alias ..="cd .."' >> /etc/bash.bashrc

# Configurar cache para Cypress
ENV CYPRESS_CACHE_FOLDER=/root/.cache/Cypress

# Configuração final
USER builder
WORKDIR /home/builder

EXPOSE 2222 8000

CMD ["/usr/sbin/sshd", "-D", "-p", "2222"]

# ENTRYPOINT ["/scripts/entrypoint.sh"]
