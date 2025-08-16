### README.md - DevOps Stack

# DevOps Stack Completa

Esta stack DevOps integra todas as ferramentas essenciais para desenvolvimento moderno, CI/CD, monitoramento e gestão de código em uma única solução containerizada.

![DevOps Architecture](docs/architecture/diagrams/devops-architecture.png)

## 🚀 Como Iniciar

### Pré-requisitos
- Docker 20.10+
- Docker Compose 2.0+
- Acesso root/sudo
- 4GB RAM mínimo (8GB recomendado)

### Configuração Inicial
```bash
# 1. Clonar repositório
git clone https://github.com/seu-usuario/devops-stack.git
cd devops-stack

# 2. Configurar ambiente
cp .env.example .env
nano .env  # Editar variáveis conforme necessário

# 3. Configurar DNS local (Linux/Mac)
echo "127.0.0.1 gitea.local drone.local sonar.local grafana.local dashboard.local" | sudo tee -a /etc/hosts

# 4. Iniciar a stack
make up
```

### Comandos Úteis
```bash
# Iniciar toda a stack
make up

# Parar a stack
make down

# Backup manual
make backup

# Verificar saúde dos serviços
make health-check

# Monitorar logs
make logs
```

## 🌐 Como Acessar Cada Serviço

| Serviço         | URL                          | Credenciais Padrão           |
|-----------------|------------------------------|-----------------------------|
| Gitea (Git)     | http://gitea.local           | admin / senha_do_admin      |
| Drone CI        | http://drone.local           | Usuário do Gitea            |
| SonarQube       | http://sonar.local           | admin / admin               |
| Grafana         | http://grafana.local         | $GRAFANA_ADMIN_USER / $GRAFANA_ADMIN_PASSWORD |
| Prometheus      | http://prometheus.local:9090 | -                           |
| cAdvisor        | http://cadvisor.local:8080   | -                           |
| Dashboard       | http://dashboard.local       | -                           |

> **Nota:** As credenciais são definidas no arquivo `.env`

## 💾 Como Fazer Backup

### Backup Automático
- Executado diariamente às 02:00 AM
- Armazenado em `./backup/automated/`
- Inclui:
  - Banco de dados PostgreSQL
  - Dados do Gitea
  - Dados do SonarQube
  - Metadados do Docker

### Backup Manual
```bash
# Executar backup completo
make backup

# Localização dos backups:
ls -lh backup/automated/*/*
```

### Restauração
```bash
# 1. Identificar backup mais recente
LATEST_BACKUP=$(ls -td ./backup/automated/* | head -1)

# 2. Parar serviços relacionados
docker-compose stop postgres_dbx gitea sonarqube

# 3. Restaurar PostgreSQL
gunzip < $LATEST_BACKUP/postgres_*.sql.gz | docker-compose exec -T postgres_dbx psql -U ${POSTGRES_USER}

# 4. Restaurar Gitea
tar -xzf $LATEST_BACKUP/gitea_*.tar.gz -C ./data/gitea

# 5. Restaurar SonarQube
tar -xzf $LATEST_BACKUP/sonarqube_*.tar.gz -C ./data/sonarqube/data

# 6. Reiniciar serviços
docker-compose up -d
```

## 🛠 Como Adicionar Novos Repositórios no Drone

### 1. Ativar repositório no Drone
1. Acesse http://drone.local
2. Faça login com sua conta do Gitea
3. Navegue até seu repositório
4. Clique em "ACTIVATE REPOSITORY"

### 2. Configurar o arquivo .drone.yml
Crie um arquivo `.drone.yml` na raiz do repositório:

```yaml
kind: pipeline
type: ssh
name: CI Pipeline

trigger:
  event: [push, pull_request, tag]

server:
  host: build-server-node
  user: root
  ssh_key:
    from_secret: BUILD_SERVER_SSH_KEY

steps:
  - name: Build and Test
    commands:
      - echo "Iniciando pipeline..."
      - npm install
      - npm test
```

### 3. Adicionar segredos (opcional)
Para variáveis sensíveis como tokens de API:

```bash
drone secret add \
  --name SONAR_TOKEN \
  --value seu_token_sonar \
  --repository seu-usuario/seu-repositorio
```

### 4. Testar o pipeline
Faça um push para o repositório:
```bash
git add .drone.yml
git commit -m "Adiciona pipeline CI"
git push origin main
```

## 🔍 Monitoramento e Métricas

### Painéis Disponíveis
1. **Visão Geral da Stack**: ID 1860
2. **Desempenho de Containers**: ID 193
3. **Métricas de Aplicação**: ID 14282
4. **Logs Consolidados**: Configurar fonte Loki

Para importar:
1. Acesse http://grafana.local
2. Navegue para "Create" > "Import"
3. Insira o ID do dashboard

### Consultas Úteis
```promql
# Uso de CPU por container
sum(rate(container_cpu_usage_seconds_total[5m])) by (container_label_com_docker_compose_service)

# Memória utilizada
container_memory_working_set_bytes{container_label_com_docker_compose_service!=""}

# Healthcheck status
container_health_status{state!="healthy"}
```

## 🧪 Testes e Qualidade

### Fluxo de CI
1. Push/Pull Request inicia pipeline
2. Etapas sequenciais:
   - Análise estática (lint)
   - Testes unitários
   - Verificação de segurança (Trivy)
   - Análise de qualidade (SonarQube)
   - Deploy condicional

### Executar testes localmente
```bash
# Testes de unidade
docker-compose exec build-server-node npm test

# Verificação de segurança
docker-compose exec build-server-node trivy fs .

# Análise SonarQube
docker-compose exec build-server-node sonar-scanner
```

## 🔒 Segurança

### Melhores Práticas
1. **Atualize regularmente**:
   ```bash
   docker-compose pull
   docker-compose up -d --force-recreate
   ```
   
2. **Gere novos secrets**:
   ```bash
   openssl rand -hex 32
   ```

3. **Revise vulnerabilidades**:
   ```bash
   make security-scan
   ```

4. **Acesse relatórios**:
   http://dashboard.local/reports/

## 📁 Estrutura de Diretórios

```
devops-stack/
├── backup/          # Scripts e dados de backup
├── config/          # Configurações de serviços
├── data/            # Dados persistentes
├── docs/            # Documentação técnica
├── infra/           # Definições de infraestrutura
├── monitoring/      # Configurações de monitoramento
├── scripts/         # Scripts utilitários
├── secrets/         # Dados sensíveis (não versionado)
└── tests/           # Testes automatizados
```

## ⚙ Variáveis de Ambiente Críticas

| Variável               | Descrição                             | Como Gerar                    |
|------------------------|---------------------------------------|-------------------------------|
| `GITEA_SECRET_KEY`     | Chave secreta do Gitea                | `openssl rand -hex 64`        |
| `DRONE_RPC_SECRET`     | Segredo para comunicação Drone        | `openssl rand -hex 32`        |
| `POSTGRES_PASSWORD`    | Senha do PostgreSQL                   | `openssl rand -hex 16`        |
| `GRAFANA_ADMIN_PASSWORD`| Senha do Grafana                     | `openssl rand -hex 16`        |

> **Atenção:** Nunca commit o arquivo `.env` no repositório!

## 🤝 Contribuição

1. Reporte issues no [GitHub Issues](https://github.com/seu-usuario/devops-stack/issues)
2. Siga o padrão de branches:
   - `feature/`: Novas funcionalidades
   - `fix/`: Correções de bugs
   - `docs/`: Atualizações de documentação

## 📄 Licença

Este projeto está licenciado sob a [MIT License](LICENSE).

---
**Manutenção**: Equipe DevOps - 2024  
**Status do Ambiente**: ![Health Status](https://img.shields.io/badge/status-production-green)
```

## 📌 Como Atualizar o README

1. Crie o arquivo na raiz do projeto:
   ```bash
   nano README.md
   ```

2. Cole o conteúdo acima

3. Personalize as seções:
   - Adicione seu nome/repositório
   - Atualize URLs de serviços
   - Ajuste instruções específicas

4. Adicione diagramas:
   ```bash
   # Instalar PlantUML
   sudo apt-get install plantuml
   
   # Gerar diagramas
   cd docs/architecture/diagrams
   make diagrams
   ```

5. Commit e push:
   ```bash
   git add README.md
   git commit -m "Adiciona documentação completa"
   git push origin main
   ```

## 💡 Dicas de Manutenção

1. **Atualize regularmente**:
   - Rode `docker-compose pull` mensalmente
   - Atualize versões no `.env`

2. **Revise documentação**:
   - Atualize o README após mudanças significativas
   - Mantenha os runbooks atualizados

3. **Teste procedimentos**:
   ```bash
   # Testar backup/restore
   ./tests/backup-restore-test.sh
   
   # Testar deploy
   ./tests/deploy-test.sh
   ```