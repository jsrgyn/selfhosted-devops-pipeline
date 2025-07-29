#!/bin/bash

# Script para limpar diretórios de dados, preservando .gitkeep

echo "🧹 Iniciando limpeza de diretórios de dados..."

# Lista de diretórios a serem limpos
directories=(
    "data/gitea/repositories"
    "data/gitea/git/repositories"
    "data/gitea/gitea"
    "data/gitea/ssh"
    "data/gitea/git/.ssh"
    "data/gitea/git/lfs"
    "data/gitea/data"
    "data/gitea/log"
    "data/gitea/avatars"
    "data/postgres/data"
    "data/postgres/pgdata"
    "data/sonarqube/data"
    "data/sonarqube/extensions"
    "data/sonarqube/logs"
    "data/drone/data"
    "data/build-server/builds"
    "data/build-server/cache"
    "data/build-server/artifacts"
)

# Função para limpar um diretório
clean_directory() {
    local dir="$1"
    if [ -d "$dir" ]; then
        echo "📁 Limpando $dir..."
        # Remove todos os arquivos e pastas, exceto .gitkeep
        find "$dir" -mindepth 1 -maxdepth 1 \
            -not -name ".gitkeep" \
            -exec rm -rf {} + 2>/dev/null || true
    elif [ -e "$dir" ]; then
        echo "❌ '$dir' existe mas não é um diretório. Pulando..."
    else
        echo "📂 '$dir' não encontrado. Pulando..."
    fi
}

# Limpa cada diretório na lista
for dir in "${directories[@]}"; do
    clean_directory "$dir"
done

echo "✅ Limpeza concluída!"