#!/bin/bash

# =============================================================================
# DEVOPS STACK SETUP SCRIPT
# Script para configuração automatizada do ambiente
# =============================================================================

set -e  # Parar em caso de erro

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Detectar sistema operacional
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        info "Sistema detectado: macOS"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        info "Sistema detectado: Linux"
    else
        OS="unknown"
        warning "Sistema não identificado, assumindo Linux"
    fi
}

# Verificar se o usuário é root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "Este script não deve ser executado como root!"
        exit 1
    fi
}

# Verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    if ! command -v docker &> /dev/null; then
        error "Docker não encontrado. Instale o Docker primeiro."
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose não encontrado. Instale o Docker Compose primeiro."
        exit 1
    fi
    
    info "✓ Docker: $(docker --version)"
    info "✓ Docker Compose: $(docker-compose --version)"
}

# Gerar tokens seguros
generate_secrets() {
    log "Gerando tokens de segurança..."
    
    # Verificar se openssl está disponível
    if ! command -v openssl &> /dev/null; then
        error "openssl não encontrado. Necessário para gerar tokens seguros."
        exit 1
    fi
    
    # Gerar tokens
    GITEA_SECRET_KEY=$(openssl rand -hex 32)
    GITEA_INTERNAL_TOKEN=$(openssl rand -hex 64)
    GITEA_OAUTH2_JWT_SECRET=$(openssl rand -hex 32)
    DRONE_RPC_SECRET=$(openssl rand -hex 32)
    DRONE_WEBHOOK_SECRET=$(openssl rand -hex 32)
    
    info "✓ Tokens de segurança gerados"
}

# Função para substituir strings no arquivo .env compatível com macOS e Linux
replace_in_file() {
    local file="$1"
    local old_string="$2"
    local new_string="$3"
    
    if [[ "$OS" == "macos" ]]; then
        # macOS requer backup extension (usando '' para não criar backup)
        sed -i '' "s|$old_string|$new_string|g" "$file"
    else
        # Linux
        sed -i "s|$old_string|$new_string|g" "$file"
    fi
}

# Atualizar arquivo .env com tokens gerados
update_env_file() {
    log "Atualizando arquivo .env com tokens seguros..."
    
    if [[ ! -f .env ]]; then
        error "Arquivo .env não encontrado!"
        exit 1
    fi
    
    # Backup do arquivo original
    cp .env .env.backup
    
    # Substituir tokens no arquivo .env usando função compatível
    replace_in_file ".env" "your-secret-key-here-change-this-to-a-secure-random-string-64-chars" "$GITEA_SECRET_KEY"
    replace_in_file ".env" "your-internal-token-here-change-this-to-a-secure-random-string-128-chars" "$GITEA_INTERNAL_TOKEN"
    replace_in_file ".env" "your-oauth2-jwt-secret-here-change-this-to-a-secure-random-string" "$GITEA_OAUTH2_JWT_SECRET"
    replace_in_file ".env" "your-drone-rpc-secret-here-change-this-to-a-secure-random-string" "$DRONE_RPC_SECRET"
    replace_in_file ".env" "your-webhook-secret-here-change-this-to-a-secure-random-string" "$DRONE_WEBHOOK_SECRET"
    
    info "✓ Arquivo .env atualizado"
}

# Configurar hosts file
setup_hosts() {
    log "Configurando /etc/hosts..."
    
    HOST_ENTRY="127.0.0.1 devops.local"
    
    if ! grep -q "devops.local" /etc/hosts; then
        echo "$HOST_ENTRY" | sudo tee -a /etc/hosts > /dev/null
        info "✓ Entrada adicionada ao /etc/hosts"
    else
        warning "devops.local já existe no /etc/hosts"
    fi
}

# Criar estrutura de diretórios
create_directories() {
    log "Criando estrutura de diretórios..."
    
    directories=(
        "nginx/conf.d"
        "nginx/ssl"
        "nginx/logs"
        "nginx/html/dashboard"
        "data/gitea"
        "data/drone"
        "data/sonarqube"
        "data/postgres"
        "backups"
        "logs"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        info "✓ Criado: $dir"
    done
}

# Configurar permissões
set_permissions() {
    log "Configurando permissões..."
    
    # Permissões para dados
    chmod -R 755 data/
    chmod -R 755 nginx/
    
    # Permissões específicas
    chmod 600 .env .env.backup 2>/dev/null || true
    
    info "✓ Permissões configuradas"
}

# Iniciar serviços
start_services() {
    log "Iniciando serviços..."
    
    # Parar containers existentes se houver
    docker-compose down 2>/dev/null || true
    
    # Construir e iniciar
    docker-compose up -d --build
    
    info "✓ Serviços iniciados"
}

# Aguardar serviços ficarem prontos
wait_for_services() {
    log "Aguardando serviços ficarem prontos..."
    
    services=("postgres_dbx" "gitea_x" "sonarqube_x" "drone_server" "nginx_proxy")
    
    for service in "${services[@]}"; do
        info "Aguardando $service..."
        timeout=60
        counter=0
        
        while ! docker-compose ps "$service" | grep -q "Up"; do
            sleep 2
            counter=$((counter + 2))
            
            if [[ $counter -ge $timeout ]]; then
                error "Timeout aguardando $service"
                exit 1
            fi
        done
        
        info "✓ $service está rodando"
    done
    
    # Aguardar um pouco mais para garantir que estão totalmente prontos
    sleep 10
}

# Configuração pós-deploy
post_deploy_config() {
    log "Executando configurações pós-deploy..."
    
    # Aguardar Gitea estar totalmente pronto
    info "Aguardando Gitea ficar totalmente disponível..."
    while ! curl -s http://devops.local/gitea/api/v1/version > /dev/null; do
        sleep 5
    done
    
    info "✓ Gitea está disponível"
    
    # Instruções para configuração manual do OAuth2
    echo ""
    echo "=================================================================="
    echo "CONFIGURAÇÃO MANUAL NECESSÁRIA - OAuth2 Gitea + Drone"
    echo "=================================================================="
    echo ""
    echo "1. Acesse: http://devops.local/gitea"
    echo "2. Complete a instalação inicial do Gitea"
    echo "3. Crie um usuário admin"
    echo "4. Vá em Settings > Applications > OAuth2 Applications"
    echo "5. Crie uma nova aplicação OAuth2 com:"
    echo "   - Nome: Drone CI"
    echo "   - Redirect URI: http://devops.local/drone/login"
    echo "6. Copie o Client ID e Client Secret"
    echo "7. Atualize o arquivo .env com:"
    echo "   - DRONE_GITEA_CLIENT_ID=<seu_client_id>"
    echo "   - DRONE_GITEA_CLIENT_SECRET=<seu_client_secret>"
    echo "8. Execute: docker-compose restart drone-server drone-runner"
    echo ""
    echo "=================================================================="
}

# Mostrar informações finais
show_final_info() {
    echo ""
    echo "=================================================================="
    echo "DEVOPS STACK - INSTALAÇÃO CONCLUÍDA!"
    echo "=================================================================="
    echo ""
    echo "🌐 Acesso aos Serviços:"
    echo "   Dashboard: http://devops.local/"
    echo "   Gitea:     http://devops.local/gitea"
    echo "   Drone CI:  http://devops.local/drone"
    echo "   SonarQube: http://devops.local/sonarqube"
    echo ""
    echo "🔧 Comandos Úteis:"
    echo "   Status:    docker-compose ps"
    echo "   Logs:      docker-compose logs -f [service]"
    echo "   Restart:   docker-compose restart [service]"
    echo "   Stop:      docker-compose down"
    echo ""
    echo "📋 Credenciais Padrão:"
    echo "   SonarQube: admin/admin (altere na primeira vez)"
    echo ""
    echo "⚠️  IMPORTANTE:"
    echo "   - Complete a configuração OAuth2 conforme instruções acima"
    echo "   - Altere senhas padrão em produção"
    echo "   - Configure backup automático"
    echo ""
    echo "Sistema detectado: $OS"
    echo "=================================================================="
}

# Função principal
main() {
    echo ""
    echo "=================================================================="
    echo "DEVOPS STACK - SETUP AUTOMATIZADO"
    echo "=================================================================="
    echo ""
    
    detect_os
    check_root
    check_dependencies
    generate_secrets
    update_env_file
    setup_hosts
    create_directories
    set_permissions
    start_services
    wait_for_services
    post_deploy_config
    show_final_info
    
    log "Setup concluído com sucesso! 🚀"
}

# Executar função principal
main "$@"