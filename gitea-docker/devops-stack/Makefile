# Makefile para DevOps Stack
# Uso: make [comando]

# Variáveis
COMPOSE_FILE = docker-compose.yml
PROJECT_NAME = devops-stack
BACKUP_DIR = ./backup/$(shell date +%Y%m%d_%H%M%S)

# Cores para output
RED = \033[0;31m
GREEN = \033[0;32m
YELLOW = \033[1;33m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help setup up down restart status logs clean backup restore health check-env

# Comando padrão
.DEFAULT_GOAL := help

## Comandos Principais
help: ## Exibe esta ajuda
	@echo "$(BLUE)DevOps Stack - Comandos Disponíveis:$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Exemplo de uso:$(NC)"
	@echo "  make setup    # Primeira configuração"
	@echo "  make up       # Subir todos os serviços"
	@echo "  make logs     # Ver logs em tempo real"
	@echo ""

setup: ## Configuração inicial do projeto
	@echo "$(BLUE)🚀 Configurando o ambiente DevOps...$(NC)"
	@if [ ! -f .env ]; then \
		echo "$(YELLOW)⚠️  Criando .env a partir do template...$(NC)"; \
		cp .env.example .env; \
		echo "$(RED)❗ IMPORTANTE: Configure suas variáveis no arquivo .env antes de continuar!$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)📁 Criando estrutura de diretórios...$(NC)"
	@mkdir -p config/{nginx/{conf.d,html/{dashboard,errors},ssl},gitea,drone,postgres/{init-scripts,conf}}
	@mkdir -p data/{gitea/{repositories,data,log,avatars},postgres,sonarqube/{data,extensions,logs},drone,build-server/{builds,cache,artifacts}}
	@mkdir -p secrets/{ssh,ssl/{certificates,keys},auth}
	@mkdir -p build/{nginx,build-server,custom-images}
	@mkdir -p scripts monitoring/{prometheus,grafana/{dashboards,provisioning},logs}
	@mkdir -p backup/{automated,manual,scripts} docs/{api-docs,architecture/{diagrams,decisions}}
	@mkdir -p tests/{integration,smoke,load}
	@echo "$(GREEN)🔑 Configurando permissões...$(NC)"
	@chmod 700 secrets/
	@chmod 600 secrets/ssh/* 2>/dev/null || true
	@echo "$(GREEN)🔧 Gerando chaves SSH se não existirem...$(NC)"
	@if [ ! -f secrets/ssh/id_rsa ]; then \
		ssh-keygen -t rsa -b 4096 -f secrets/ssh/id_rsa -N "" -C "drone-runner@devops-stack"; \
	fi
	@echo "$(GREEN)📋 Criando arquivos de configuração base...$(NC)"
	@$(MAKE) create-configs
	@echo "$(GREEN)✅ Setup concluído! Execute 'make up' para iniciar os serviços.$(NC)"

create-configs: ## Cria arquivos de configuração básicos
	@echo "$(BLUE)📝 Criando configurações básicas...$(NC)"
	@if [ ! -f config/postgres/init-scripts/01-init-databases.sql ]; then \
		echo "-- Script de inicialização dos bancos" > config/postgres/init-scripts/01-init-databases.sql; \
		echo "CREATE DATABASE gitea_db;" >> config/postgres/init-scripts/01-init-databases.sql; \
		echo "CREATE DATABASE drone_db;" >> config/postgres/init-scripts/01-init-databases.sql; \
		echo "CREATE DATABASE sonarqube_db;" >> config/postgres/init-scripts/01-init-databases.sql; \
	fi

up: check-env ## Inicia todos os serviços
	@echo "$(BLUE)🚀 Iniciando o stack DevOps...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)✅ Serviços iniciados com sucesso!$(NC)"
	@$(MAKE) status

down: ## Para todos os serviços
	@echo "$(YELLOW)🛑 Parando todos os serviços...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)✅ Serviços parados com sucesso!$(NC)"

restart: ## Reinicia todos os serviços
	@echo "$(BLUE)🔄 Reiniciando todos os serviços...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) restart
	@echo "$(GREEN)✅ Serviços reiniciados com sucesso!$(NC)"

restart-service: ## Reinicia um serviço específico (uso: make restart-service SERVICE=nginx)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)❗ Uso: make restart-service SERVICE=nome_do_servico$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)🔄 Reiniciando serviço $(SERVICE)...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) restart $(SERVICE)
	@echo "$(GREEN)✅ Serviço $(SERVICE) reiniciado!$(NC)"

status: ## Mostra status dos serviços
	@echo "$(BLUE)📊 Status dos serviços:$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps

logs: ## Mostra logs de todos os serviços em tempo real
	@echo "$(BLUE)📋 Logs em tempo real (Ctrl+C para sair):$(NC)"
	@docker-compose -f $(COMPOSE_FILE) logs -f

logs-service: ## Mostra logs de um serviço específico (uso: make logs-service SERVICE=nginx)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)❗ Uso: make logs-service SERVICE=nome_do_servico$(NC)"; \
		exit 1; \
	fi
	@echo "$(BLUE)📋 Logs do serviço $(SERVICE):$(NC)"
	@docker-compose -f $(COMPOSE_FILE) logs -f $(SERVICE)

health: ## Verifica saúde dos serviços
	@echo "$(BLUE)🏥 Verificando saúde dos serviços...$(NC)"
	@./scripts/health-check.sh || echo "$(YELLOW)⚠️  Script de health check não encontrado$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

## Comandos de Backup e Restore
backup: ## Executa backup completo
	@echo "$(BLUE)💾 Iniciando backup completo...$(NC)"
	@mkdir -p $(BACKUP_DIR)
	@echo "$(YELLOW)📊 Backup do banco de dados...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec -T postgres_dbx pg_dumpall -U ${POSTGRES_USER} > $(BACKUP_DIR)/postgres_full_backup.sql
	@echo "$(YELLOW)📁 Backup dos volumes...$(NC)"
	@docker run --rm -v $(PWD)/data:/data -v $(PWD)/backup:/backup alpine tar czf /backup/$(shell basename $(BACKUP_DIR))/volumes_backup.tar.gz -C /data .
	@echo "$(YELLOW)🔧 Backup das configurações...$(NC)"
	@tar czf $(BACKUP_DIR)/config_backup.tar.gz config/
	@echo "$(YELLOW)🔑 Backup dos secrets (criptografado)...$(NC)"
	@tar czf $(BACKUP_DIR)/secrets_backup.tar.gz secrets/ && gpg --cipher-algo AES256 --compress-algo 1 --s2k-mode 3 --s2k-digest-algo SHA512 --s2k-count 65536 --symmetric --output $(BACKUP_DIR)/secrets_backup.tar.gz.gpg $(BACKUP_DIR)/secrets_backup.tar.gz && rm $(BACKUP_DIR)/secrets_backup.tar.gz
	@echo "$(GREEN)✅ Backup completo salvo em: $(BACKUP_DIR)$(NC)"

backup-db: ## Backup apenas do banco de dados
	@echo "$(BLUE)💾 Backup do banco de dados...$(NC)"
	@mkdir -p backup/database
	@docker-compose -f $(COMPOSE_FILE) exec -T postgres_dbx pg_dumpall -U ${POSTGRES_USER} > backup/database/postgres_backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)✅ Backup do banco concluído!$(NC)"

restore: ## Restaura backup (uso: make restore BACKUP_DIR=./backup/20231201_120000)
	@if [ -z "$(BACKUP_DIR)" ]; then \
		echo "$(RED)❗ Uso: make restore BACKUP_DIR=caminho_do_backup$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)⚠️  ATENÇÃO: Esta operação irá sobrescrever dados existentes!$(NC)"
	@echo "$(YELLOW)Pressione Ctrl+C nos próximos 10 segundos para cancelar...$(NC)"
	@sleep 10
	@echo "$(BLUE)🔄 Restaurando backup...$(NC)"
	@$(MAKE) down
	@echo "$(YELLOW)📁 Restaurando volumes...$(NC)"
	@docker run --rm -v $(PWD)/data:/data -v $(PWD)/backup:/backup alpine tar xzf /backup/$(shell basename $(BACKUP_DIR))/volumes_backup.tar.gz -C /data
	@echo "$(YELLOW)🔧 Restaurando configurações...$(NC)"
	@tar xzf $(BACKUP_DIR)/config_backup.tar.gz
	@$(MAKE) up
	@sleep 30
	@echo "$(YELLOW)📊 Restaurando banco de dados...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec -T postgres_dbx psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} < $(BACKUP_DIR)/postgres_full_backup.sql
	@echo "$(GREEN)✅ Restore concluído!$(NC)"

## Comandos de Manutenção
clean: ## Remove containers, volumes e imagens não utilizadas
	@echo "$(YELLOW)🧹 Limpando recursos não utilizados...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down -v --remove-orphans
	@docker system prune -f
	@docker volume prune -f
	@echo "$(GREEN)✅ Limpeza concluída!$(NC)"

clean-all: ## Remove TUDO (cuidado!)
	@echo "$(RED)⚠️  ATENÇÃO: Esta operação remove TODOS os dados!$(NC)"
	@echo "$(YELLOW)Pressione Ctrl+C nos próximos 15 segundos para cancelar...$(NC)"
	@sleep 15
	@$(MAKE) down
	@docker-compose -f $(COMPOSE_FILE) down -v --remove-orphans --rmi all
	@docker system prune -af --volumes
	@sudo rm -rf data/
	@echo "$(RED)🗑️  Todos os dados foram removidos!$(NC)"

update: ## Atualiza as imagens dos containers
	@echo "$(BLUE)🔄 Atualizando imagens...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) pull
	@echo "$(GREEN)✅ Imagens atualizadas!$(NC)"
	@echo "$(YELLOW)💡 Execute 'make restart' para aplicar as atualizações$(NC)"

## Comandos de Desenvolvimento
dev: ## Inicia em modo de desenvolvimento
	@echo "$(BLUE)🛠️  Iniciando em modo desenvolvimento...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) -f docker-compose.dev.yml up -d
	@$(MAKE) status

build: ## Reconstrói as imagens customizadas
	@echo "$(BLUE)🔨 Reconstruindo imagens...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build --no-cache
	@echo "$(GREEN)✅ Build concluído!$(NC)"

shell: ## Acesso shell a um container (uso: make shell SERVICE=nginx)
	@if [ -z "$(SERVICE)" ]; then \
		echo "$(RED)❗ Uso: make shell SERVICE=nome_do_servico$(NC)"; \
		exit 1; \
	fi
	@docker-compose -f $(COMPOSE_FILE) exec $(SERVICE) /bin/sh

## Comandos de Monitoramento
monitor: ## Inicia stack de monitoramento
	@echo "$(BLUE)📊 Iniciando monitoramento...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) --profile monitoring up -d
	@echo "$(GREEN)✅ Monitoramento ativo!$(NC)"

stats: ## Mostra estatísticas de uso dos containers
	@echo "$(BLUE)📈 Estatísticas dos containers:$(NC)"
	@docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"

## Comandos de Segurança
security-scan: ## Executa scan de segurança nos containers
	@echo "$(BLUE)🔍 Executando scan de segurança...$(NC)"
	@docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
		-v $(PWD):/tmp/.hadolint/config \
		hadolint/hadolint:latest hadolint /tmp/.hadolint/config/*/Dockerfile || true
	@echo "$(GREEN)✅ Scan de segurança concluído!$(NC)"

generate-secrets: ## Gera novos secrets para os serviços
	@echo "$(BLUE)🔑 Gerando novos secrets...$(NC)"
	@echo "GITEA_SECRET_KEY=$(shell openssl rand -hex 32)" > secrets/auth/gitea-secrets.env
	@echo "GITEA_INTERNAL_TOKEN=$(shell openssl rand -hex 32)" >> secrets/auth/gitea-secrets.env
	@echo "GITEA_OAUTH2_JWT_SECRET=$(shell openssl rand -hex 32)" >> secrets/auth/gitea-secrets.env
	@echo "DRONE_RPC_SECRET=$(shell openssl rand -hex 32)" > secrets/auth/drone-secrets.env
	@echo "$(GREEN)✅ Secrets gerados em secrets/auth/$(NC)"
	@echo "$(YELLOW)💡 Adicione estes valores ao seu arquivo .env$(NC)"

## Utilitários
check-env: ## Verifica se o arquivo .env existe
	@if [ ! -f .env ]; then \
		echo "$(RED)❗ Arquivo .env não encontrado!$(NC)"; \
		echo "$(YELLOW)💡 Execute 'make setup' primeiro$(NC)"; \
		exit 1; \
	fi

info: ## Mostra informações do ambiente
	@echo "$(BLUE)ℹ️  Informações do Ambiente:$(NC)"
	@echo "Projeto: $(PROJECT_NAME)"
	@echo "Compose File: $(COMPOSE_FILE)"
	@echo "Docker Version: $(shell docker --version)"
	@echo "Docker Compose Version: $(shell docker-compose --version)"
	@echo "Sistema: $(shell uname -a)"

ports: ## Lista as portas expostas
	@echo "$(BLUE)🌐 Portas expostas:$(NC)"
	@echo "Nginx (HTTP): 80"
	@echo "Nginx (HTTPS): 443"
	@echo "PostgreSQL: 5432"
	@echo "Build Server: 8000"
	@echo ""
	@echo "$(BLUE)🌐 Acessos via proxy:$(NC)"
	@echo "Gitea: https://gitea.local"
	@echo "Drone: https://drone.local"
	@echo "SonarQube: https://sonar.local"

test: ## Executa testes básicos de conectividade
	@echo "$(BLUE)🧪 Executando testes básicos...$(NC)"
	@./scripts/test-connectivity.sh || echo "$(YELLOW)⚠️  Script de teste não encontrado$(NC)"

## Meta comandos
install-deps: ## Instala dependências do sistema
	@echo "$(BLUE)📦 Instalando dependências...$(NC)"
	@which docker >/dev/null || (echo "$(RED)❗ Docker não instalado$(NC)" && exit 1)
	@which docker-compose >/dev/null || (echo "$(RED)❗ Docker Compose não instalado$(NC)" && exit 1)
	@which make >/dev/null || (echo "$(RED)❗ Make não instalado$(NC)" && exit 1)
	@echo "$(GREEN)✅ Todas as dependências estão instaladas!$(NC)"