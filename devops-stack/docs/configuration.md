# Documentação de Configuração - DevOps Stack

## DevOps Stack - Guia de Configuração

### Sumário
1. [Visão Geral da Arquitetura](#visão-geral-da-arquitetura)  
2. [Configuração de Rede](#configuração-de-rede)  
3. [Configuração de Volumes](#configuração-de-volumes)  
4. [Gitea](#gitea)  
5. [Drone CI](#drone-ci)  
6. [SonarQube](#sonarqube)  
7. [PostgreSQL](#postgresql)  
8. [Nginx](#nginx)  
9. [Build Server](#build-server)  
10. [Health Checks](#health-checks)  

---

## Visão Geral da Arquitetura
```mermaid
graph TD
    A[Nginx] --> B[Gitea]
    A --> C[Drone Server]
    A --> D[SonarQube]
    C --> E[Drone Runner SSH]
    E --> F[Build Server Node]
    B --> G[PostgreSQL]
    C --> G
    D --> G
```

---

## Configuração de Rede
### Rede Bridge Personalizada
```yaml
networks:
  devops-network:
    driver: bridge
    ipam:
      config:
        - subnet: 172.20.0.0/16
```

### Hosts Adicionais
```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
  - "gitea.local:172.20.0.1"
  - "drone.local:172.20.0.1"
  - "sonar.local:172.20.0.1"
```

---

## Configuração de Volumes
### Estrutura de Diretórios
```
├── config
│   ├── gitea          # Configurações do Gitea
│   ├── drone          # Configurações do Drone
│   ├── nginx          # Configurações do Nginx
│   └── postgres       # Scripts de inicialização do PostgreSQL
├── data
│   ├── gitea          # Dados persistentes do Gitea
│   ├── drone          # Dados persistentes do Drone
│   ├── sonarqube      # Dados do SonarQube
│   └── postgres       # Dados do PostgreSQL
└── secrets
    └── ssh            # Chaves SSH
```

### Volume de Cache de Build
```yaml
volumes:
  build_cache:
    name: build_cache
    driver: local
```

---

## Gitea
### Configurações Essenciais via Variáveis
```yaml
environment:
  - GITEA__database__DB_TYPE=postgres
  - GITEA__database__HOST=postgres_dbx:5432
  - GITEA__server__DOMAIN=${GITEA_DOMAIN}
  - GITEA__server__ROOT_URL=${GITEA_ROOT_URL}
  - GITEA__security__SECRET_KEY=${GITEA_SECRET_KEY}
```

### Configurações de Segurança
```yaml
  - GITEA__server__DISABLE_SSH=true
  - GITEA__session__PROVIDER=file
  - GITEA__webhook__ALLOWED_HOST_LIST=172.20.0.0/16
```

### Volumes
```yaml
volumes:
  - ./data/gitea:/data             # Dados persistentes
  - ./config/gitea:/etc/gitea      # Arquivos de configuração
```

---

## Drone CI
### Drone Server
```yaml
environment:
  - DRONE_GITEA_SERVER=${DRONE_GITEA_SERVER}
  - DRONE_GITEA_CLIENT_ID=${DRONE_GITEA_CLIENT_ID}
  - DRONE_GITEA_CLIENT_SECRET=${DRONE_GITEA_CLIENT_SECRET}
  - DRONE_RPC_SECRET=${DRONE_RPC_SECRET}
  - DRONE_SERVER_HOST=${DRONE_SERVER_HOST}
  - DRONE_DATABASE_DATASOURCE=postgres://${DRONE_DATABASE_USER}:${DRONE_DB_PASSWORD}@postgres_dbx:5432/${DRONE_DATABASE}?sslmode=disable
```

### Drone Runner SSH
```yaml
environment:
  - DRONE_RPC_PROTO=${DRONE_SERVER_PROTO}
  - DRONE_RPC_HOST=${DRONE_RPC_HOST}
  - DRONE_RUNNER_LABELS=environment:ssh-build,arch:arm64
volumes:
  - ./secrets/ssh/id_rsa.pub:/root/.ssh/authorized_keys:ro
```

---

## SonarQube
### Configuração Principal
```yaml
environment:
  - SONAR_JDBC_URL=jdbc:postgresql://postgres_dbx:5432/${SONARQUBE_DB_NAME}
  - SONAR_JDBC_USERNAME=${SONARQUBE_DB_USER}
  - SONAR_JDBC_PASSWORD=${SONARQUBE_DB_PASSWORD}
  - SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true
```

### Limites de Sistema
```yaml
ulimits:
  memlock:
    soft: -1
    hard: -1
  nofile:
    soft: 65536
    hard: 65536
```

---

## PostgreSQL
### Inicialização do Banco
```bash
#!/bin/bash
# config/postgres/init-scripts/01-init-databases.sh

CREATE USER "$SONARQUBE_DB_USER" WITH PASSWORD '$SONARQUBE_DB_PASSWORD';
CREATE DATABASE sonarqube OWNER "$SONARQUBE_DB_USER";
GRANT ALL PRIVILEGES ON DATABASE sonarqube TO "$SONARQUBE_DB_USER";
```

### Configuração de Portas
```yaml
ports:
  - "${POSTGRES_PORT:-5432}:5432"
```

---

## Nginx
### Configuração de Proxy Reverso
```nginx
# config/nginx/conf.d/gitea.conf
server {
    listen 80;
    server_name gitea.local;

    location / {
        proxy_pass http://gitea:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Volumes
```yaml
volumes:
  - ./config/nginx/nginx.conf:/etc/nginx/nginx.conf:ro
  - ./config/nginx/conf.d:/etc/nginx/conf.d:ro
  - ./config/nginx/ssl:/etc/nginx/ssl:ro
```

---

## Build Server
### Dockerfile Principal
```dockerfile
FROM --platform=linux/arm64 ubuntu:jammy

# Instalação de dependências
RUN apt-get update && apt-get install -y \
    openssh-server nodejs python3-pip sonar-scanner

# Configuração SSH
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
```

### Configuração no Compose
```yaml
build:
  context: ./infra/docker/build-server
  args:
    NODE_VERSION: "${NODE_VERSION}"
volumes:
  - ./secrets/ssh/id_rsa.pub:/root/.ssh/authorized_keys:ro
  - ./data/build-server:/root/builds
  - build_cache:/root/.cache
```

---

## Health Checks
### Exemplo para PostgreSQL
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 30s
```

### Exemplo para Gitea
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:3000/"]
  interval: 30s
  timeout: 10s
  retries: 3
```

### Exemplo para SonarQube
```yaml
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:9000/api/system/status"]
  interval: 30s
  timeout: 10s
  retries: 5
  start_period: 60s
```

---

## Melhores Práticas de Configuração
1. **Secrets Management**:
   ```bash
   # Gerar novos secrets
   openssl rand -hex 32
   ```
   
2. **Versionamento de Configurações**:
   - Manter `config/` no controle de versão (exceto secrets)
   - Ignorar `data/` e `secrets/` no `.gitignore`

3. **Atualização Segura**:
   ```bash
   # Testar configurações antes de aplicar
   docker-compose config
   docker-compose up -d --force-recreate --no-deps --build <service>
   ```

4. **Backup de Configurações**:
   ```bash
   # Compactar configurações
   tar -czvf config_backup_$(date +%Y%m%d).tar.gz config/ .env
   ```

> **Nota**: Para configurações avançadas, consulte a documentação oficial de cada serviço