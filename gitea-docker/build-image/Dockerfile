# ==============================================================================
# Dockerfile para Servidor de Build (Ubuntu ARM64)
# Contém: SSH, Git, Node.js, Yarn, e ferramentas essenciais de build.
# ==============================================================================

# Use a imagem oficial do Ubuntu para ARM64 como base.
FROM --platform=linux/arm64 ubuntu:jammy

ENV DEBIAN_FRONTEND=noninteractive

# Atualiza os pacotes, instala o servidor SSH e as ferramentas básicas.
RUN apt-get update && apt-get install -y --no-install-recommends \
    openssh-server \
    sudo \
    git \
    curl \
    ca-certificates \
    apt-utils \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Instala Node.js e Yarn usando o repositório oficial da NodeSource.
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get install -y nodejs \
    && npm install -g yarn

# Configura o servidor SSH.
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
    && sed -i 's/root:\*:/root::/' /etc/shadow \
    && sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    # --- CORREÇÃO AQUI ---
    # Cria o diretório necessário para a separação de privilégios do SSHD.
    && mkdir /run/sshd

# Cria o diretório para as chaves SSH do usuário root.
RUN mkdir -p /root/.ssh && chmod 700 /root/.ssh

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]