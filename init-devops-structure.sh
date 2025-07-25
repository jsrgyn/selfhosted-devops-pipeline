#!/bin/bash

# Script para inicializar a estrutura da DevOps Stack com suporte completo a Dockerfiles customizados
# Autor: Johnathan Silva Resende
# Data: 21/07/2025

set -e  # Para em caso de erro

echo "🚀 Iniciando criação da estrutura DevOps Stack..."

# Diretório raiz
PROJECT_DIR="devops-stack"

# Criar diretório principal se não existir
if [ ! -d "$PROJECT_DIR" ]; then
    mkdir -p "$PROJECT_DIR"
    echo "✅ Criado diretório principal: $PROJECT_DIR"
else
    echo "⚠️  Diretório $PROJECT_DIR já existe"
fi

cd "$PROJECT_DIR"

echo "📁 Criando estrutura de diretórios..."

# Config directories
mkdir -p config/{nginx/{conf.d,html/{dashboard/assets,errors},ssl/{certs,private}},gitea,drone,postgres/{init-scripts,conf}}

# Data directories
mkdir -p data/{gitea/{repositories,data,log,avatars},postgres/data,sonarqube/{data,extensions,logs},drone/data,build-server/{builds,cache,artifacts}}

# Secrets directories
mkdir -p secrets/{ssh,ssl/{certificates,keys},auth}

# Build directories
mkdir -p infra/docker/{nginx,build-server/{scripts,config},custom-images,base/{debian,node}}  # base: imagens reutilizáveis

# Scripts directory
mkdir -p scripts

# Monitoring directories
mkdir -p monitoring/{prometheus,grafana/{dashboards,provisioning},logs/{fluentd,elasticsearch}}

# Backup directories
mkdir -p backup/{automated,manual,scripts}

# Documentation directories
mkdir -p docs/{api-docs,architecture/{diagrams,decisions}}

# Test directories
mkdir -p tests/{integration,smoke,load}

echo "📄 Criando arquivos de configuração básicos..."

# Arquivos raiz
touch README.md docker-compose.yml docker-compose.override.yml.example .env.example .env .gitignore Makefile

# Configuração do Nginx
mkdir -p config/nginx/conf.d
cat > config/nginx/conf.d/default.conf << 'EOF'
# default.conf para nginx reverso
EOF

# Arquivos de configuração adicionais
for svc in gitea drone sonar; do
    touch config/nginx/conf.d/${svc}.conf
done

# HTML
touch config/nginx/html/dashboard/index.html
for err in 404 50x; do
    touch config/nginx/html/errors/${err}.html
done

# Configs específicas
cat > config/gitea/app.ini.template << 'EOF'
[server]
DOMAIN=localhost
EOF

touch config/drone/{server.conf,runner.conf}
touch config/postgres/init-scripts/01-init-databases.sql
cat > config/postgres/conf/postgresql.conf << 'EOF'
# PostgreSQL personalizado
EOF

# Secrets simulados
touch secrets/ssh/{id_rsa,id_rsa.pub,known_hosts}
touch secrets/auth/{oauth-secrets.env,jwt-tokens.env}

# Dockerfiles e scripts
cat > infra/docker/nginx/Dockerfile << 'EOF'
FROM nginx:alpine
COPY ./config/nginx /etc/nginx/
EOF

cat > infra/docker/build-server/Dockerfile << 'EOF'
FROM debian:bullseye-slim
COPY ./scripts /scripts
RUN chmod +x /scripts/*.sh
ENTRYPOINT ["/scripts/entrypoint.sh"]
EOF

touch infra/docker/build-server/entrypoint.sh
for script in setup-node.sh install-tools.sh; do
    touch infra/docker/build-server/scripts/${script}
    chmod +x infra/docker/build-server/scripts/${script}
done

# Scripts principais
touch scripts/{setup.sh,backup.sh,restore.sh,health-check.sh,deploy.sh}

# Permissões
chmod +x scripts/*.sh backup/scripts/*.sh infra/docker/build-server/entrypoint.sh
chmod 600 secrets/ssh/id_rsa secrets/auth/*.env
chmod 644 secrets/ssh/id_rsa.pub

# .gitignore básico
cat > .gitignore << 'EOF'
.env
*.env
data/
!data/.gitkeep
secrets/
!secrets/.gitkeep
*.log
logs/
backup/automated/
backup/manual/
.vscode/
.idea/
*.swp
*.swo
.DS_Store
Thumbs.db
docker-compose.override.yml
*.tmp
*.temp
infra/docker/*/target/
infra/docker/*/dist/
node_modules/
EOF

# .gitkeep para diretórios vazios
find . -type d -empty -exec touch {}/.gitkeep \;

# Finalização
echo ""
echo "✅ Estrutura DevOps Stack criada com sucesso!"
echo ""
echo "📊 Resumo da criação:"
echo "   - Diretórios criados: $(find . -type d | wc -l)"
echo "   - Arquivos criados: $(find . -type f | wc -l)"
echo ""
echo "📍 Localização: $(pwd)"
echo ""
echo "🎯 Próximos passos:"
echo "   1. Configure os arquivos .env e docker-compose.yml"
echo "   2. Execute os scripts de configuração em scripts/"
echo "   3. Revise as configurações em config/"
echo "   4. Configure os secrets em secrets/"
echo ""
echo "🔗 Para mais informações, consulte a documentação em docs/"
echo "🚀 Stack DevOps pronta para uso!"