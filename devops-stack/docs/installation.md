# Guia de Instalação - DevOps Stack

## DevOps Stack - Guia de Instalação

## Pré-requisitos
- **Docker**: versão 20.10.7+
- **Docker Compose**: versão 1.29.2+
- **Linux/ARM64** (ou ajustar imagens para sua arquitetura)
- **Git**
- **OpenSSL** (para geração de secrets)
- **4GB RAM** mínimo (recomendado 8GB+)
- **10GB** de espaço em disco

---

## Passo 1: Configuração Inicial

### 1.1. Estrutura de Diretórios
```bash
mkdir -p devops-stack/{data,config,secrets,infra/docker/build-server}
cd devops-stack
```

### 1.2. Criar Arquivos Essenciais
```bash
touch docker-compose.yml .env Dockerfile
mkdir -p config/{gitea,drone,nginx,postgres/init-scripts}
```

---

## Passo 2: Configurar Variáveis de Ambiente (.env)

### 2.1. Criar arquivo .env
```bash
cat > .env <<EOL
# CONFIGURAÇÕES GERAIS
USER_UID=$(id -u)
USER_GID=$(id -g)
TZ=America/Sao_Paulo

# POSTGRESQL
POSTGRES_USER=postgres
POSTGRES_PASSWORD=$(openssl rand -hex 16)
POSTGRES_DB=postgres

# GITEA
GITEA_DATABASE=gitea
GITEA_DATABASE_USER=gitea_user
GITEA_DB_PASSWORD=$(openssl rand -hex 16)
GITEA_DOMAIN=gitea.local
GITEA_ROOT_URL=http://gitea.local
GITEA_SECRET_KEY=$(openssl rand -hex 32)
GITEA_INTERNAL_TOKEN=$(openssl rand -hex 40)
GITEA_OAUTH2_JWT_SECRET=$(openssl rand -hex 32)

# DRONE
DRONE_DATABASE=drone
DRONE_DATABASE_USER=drone_user
DRONE_DB_PASSWORD=$(openssl rand -hex 16)
DRONE_SERVER_HOST=drone.local
DRONE_SERVER_PROTO=http
DRONE_RPC_HOST=drone_server
DRONE_RPC_SECRET=$(openssl rand -hex 32)
DRONE_GITEA_CLIENT_ID=$(uuidgen)
DRONE_GITEA_CLIENT_SECRET=$(openssl rand -hex 32)
DRONE_ADMIN_USER=admin
DRONE_RUNNER_NAME=ssh-runner
DRONE_WEBHOOK_SECRET=$(openssl rand -hex 32)
DRONE_GITEA_SERVER=http://gitea.local

# SONARQUBE
SONARQUBE_DB_NAME=sonarqube
SONARQUBE_DB_USER=sonar_user
SONARQUBE_DB_PASSWORD=$(openssl rand -hex 16)

# NGINX
NGINX_PORT=80
NGINX_SSL_PORT=443

# BUILD SERVER
NODE_VERSION=18
EOL
```

### 2.2. Gerar Chaves SSH
```bash
mkdir -p secrets/ssh
ssh-keygen -t rsa -b 4096 -f secrets/ssh/id_rsa -N ""
```

---

## Passo 3: Configurar Docker Compose

### 3.1. Criar docker-compose.yml
```yaml
# docker-compose.yml
version: "3.8"

services:
  # [Serviços conforme fornecido anteriormente]
  # Copiar conteúdo completo do docker-compose fornecido

networks:
  devops-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16

volumes:
  build_cache:
    driver: local
```

---

## Passo 4: Configurar Banco de Dados

### 4.1. Criar script de inicialização
```bash
cat > config/postgres/init-scripts/01-init-databases.sh <<'EOL'
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER "$SONARQUBE_DB_USER" WITH PASSWORD '$SONARQUBE_DB_PASSWORD';
    CREATE USER "$GITEA_DATABASE_USER" WITH PASSWORD '$GITEA_DB_PASSWORD';
    CREATE USER "$DRONE_DATABASE_USER" WITH PASSWORD '$DRONE_DB_PASSWORD';
    
    CREATE DATABASE sonarqube OWNER "$SONARQUBE_DB_USER";
    CREATE DATABASE gitea OWNER "$GITEA_DATABASE_USER";
    CREATE DATABASE drone OWNER "$DRONE_DATABASE_USER";
    
    GRANT ALL PRIVILEGES ON DATABASE sonarqube TO "$SONARQUBE_DB_USER";
    GRANT ALL PRIVILEGES ON DATABASE gitea TO "$GITEA_DATABASE_USER";
    GRANT ALL PRIVILEGES ON DATABASE drone TO "$DRONE_DATABASE_USER";
EOSQL
EOL

chmod +x config/postgres/init-scripts/01-init-databases.sh
```

---

## Passo 5: Configurar Build Server

### 5.1. Criar Dockerfile
```bash
mkdir -p infra/docker/build-server
cat > infra/docker/build-server/Dockerfile <<'EOL'
FROM --platform=linux/arm64 ubuntu:jammy

# [Conteúdo completo do Dockerfile fornecido]
# Copiar conteúdo do Dockerfile fornecido
EOL
```

---

## Passo 6: Iniciar a Stack

### 6.1. Build e Inicialização
```bash
docker-compose up -d --build
```

### 6.2. Verificar Status
```bash
docker-compose ps
docker-compose logs -f
```

---

## Passo 7: Configuração Pós-Instalação

### 7.1. Configurar Gitea
1. Acessar: http://localhost:3000 (ou via Nginx se configurado)
2. Primeiro acesso:
   - URL do servidor: http://gitea.local
   - Nome do servidor de banco de dados: postgres_dbx
   - Usuário: ${GITEA_DATABASE_USER} (do .env)
   - Senha: ${GITEA_DB_PASSWORD} (do .env)
   - Nome do banco de dados: gitea

### 7.2. Configurar OAuth no Gitea (para Drone)
1. Acessar: **Settings > Applications**
2. Criar nova aplicação:
   - Application Name: Drone CI
   - Redirect URI: http://drone.local/login
3. Salvar Client ID e Client Secret (atualizar no .env)

### 7.3. Configurar Drone
1. Acessar: http://drone.local
2. Fazer login com conta do Gitea
3. Ativar repositórios desejados

---

## Passo 8: Configurar DNS Local

### 8.1. Adicionar ao /etc/hosts
```bash
echo "127.0.0.1 gitea.local drone.local sonar.local" | sudo tee -a /etc/hosts
```

### 8.2. Verificar Acesso
```bash
curl -I http://gitea.local
curl -I http://drone.local
curl -I http://sonar.local
```

---

## Passo 9: Manutenção Básica

### 9.1. Comandos Úteis
```bash
# Parar stack
docker-compose down

# Iniciar específicos serviços
docker-compose up -d gitea postgres_dbx

# Backup de volumes
tar -czvf backup_$(date +%Y%m%d).tar.gz data/

# Atualizar containers
docker-compose pull
docker-compose up -d --build
```

### 9.2. Limpeza
```bash
# Remover containers parados
docker container prune

# Limpar cache de build
docker volume rm $(docker volume ls -q | grep build_cache)
```

---

## Solução de Problemas
Consulte o [TROUBLESHOOTING.md](TROUBLESHOOTING.md) para problemas comuns:

1. Conexão entre containers
2. Problemas de inicialização
3. Erros de banco de dados
4. Configuração de rede
5. Permissões de volumes

> **Nota de Segurança**: 
> - Nunca comite arquivos .env ou secrets no Git
> - Para produção, utilize um gerenciador de secrets
> - Atualize todas as senhas geradas automaticamente
> - Configure HTTPS com certificados válidos