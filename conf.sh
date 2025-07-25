# Clone ou crie o diretório
mkdir gitea-docker && cd gitea-docker

# Crie os arquivos necessários
touch docker-compose.yml .env .gitignore

# Crie os diretórios
mkdir -p {data,config,logs,backups}