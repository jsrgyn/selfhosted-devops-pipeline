# Estrutura de Pastas Recomendada - DevOps Stack

```
devops-stack/
├── README.md
├── docker-compose.yml
├── docker-compose.override.yml.example
├── .env.example
├── .env
├── .gitignore
├── Makefile
│
├── config/
│   ├── nginx/
│   │   ├── nginx.conf
│   │   ├── conf.d/
│   │   │   ├── default.conf
│   │   │   ├── gitea.conf
│   │   │   ├── drone.conf
│   │   │   └── sonar.conf
│   │   ├── html/
│   │   │   ├── dashboard/
│   │   │   │   ├── index.html
│   │   │   │   └── assets/
│   │   │   └── errors/
│   │   │       ├── 404.html
│   │   │       └── 50x.html
│   │   └── ssl/
│   │       ├── certs/
│   │       └── private/
│   ├── gitea/
│   │   └── app.ini.template
│   ├── drone/
│   │   ├── server.conf
│   │   └── runner.conf
│   └── postgres/
│       ├── init-scripts/
│       │   └── 01-init-databases.sql
│       └── conf/
│           └── postgresql.conf
│
├── data/
│   ├── gitea/
│   │   ├── repositories/
│   │   ├── data/
│   │   ├── log/
│   │   └── avatars/
│   ├── postgres/
│   │   └── data/
│   │   └── pgdata/
│   ├── sonarqube/
│   │   ├── data/
│   │   ├── extensions/
│   │   └── logs/
│   ├── drone/
│   │   └── data/
│   └── build-server/
│       ├── builds/
│       ├── cache/
│       └── artifacts/
│
├── secrets/
│   ├── ssh/
│   │   ├── id_rsa
│   │   ├── id_rsa.pub
│   │   └── known_hosts
│   ├── ssl/
│   │   ├── certificates/
│   │   └── keys/
│   └── auth/
│       ├── oauth-secrets.env
│       └── jwt-tokens.env
│
├── infra/docker/
│         ├── nginx/
│         │   └── Dockerfile
│         ├── build-server/
│         │   ├── Dockerfile
│         │   ├── entrypoint.sh
│         │   └── scripts/
│         │       ├── setup-node.sh
│         │       └── install-tools.sh
│         └── custom-images/
│
├── scripts/
│   ├── setup.sh
│   ├── backup.sh
│   ├── restore.sh
│   ├── health-check.sh
│   └── deploy.sh
│
├── monitoring/
│   ├── prometheus/
│   │   └── prometheus.yml
│   ├── grafana/
│   │   ├── dashboards/
│   │   └── provisioning/
│   └── logs/
│       ├── fluentd/
│       └── elasticsearch/
│
├── backup/
│   ├── automated/
│   ├── manual/
│   └── scripts/
│       ├── backup-postgres.sh
│       ├── backup-gitea.sh
│       └── backup-volumes.sh
│
├── docs/
│   ├── installation.md
│   ├── configuration.md
│   ├── troubleshooting.md
│   ├── api-docs/
│   └── architecture/
│       ├── diagrams/
│       └── decisions/
│
└── tests/
    ├── integration/
    ├── smoke/
    └── load/
```

## Detalhamento dos Diretórios

### `/config/` - Configurações
- Arquivos de configuração para todos os serviços da stack
- Templates e ajustes finos para Gitea, Drone, Nginx e Postgres

### `/data/` - Dados Persistentes
- Diretórios mapeados para volumes Docker
- Armazena dados que não devem ser perdidos entre reinícios ou rebuilds

### `/secrets/` - Informações Sensíveis
- Armazena chaves SSH, certificados SSL, tokens e senhas
- Deve ser protegido e nunca versionado em repositórios públicos

### `/build/` - Imagens Customizadas
- Dockerfiles e scripts de build para containers personalizados
- Inclui `entrypoint.sh` e ferramentas auxiliares

### `/scripts/` - Automação
- Scripts utilitários para setup, deploy, health check e backups
- Usados diretamente pelo `Makefile` ou manualmente

### `/monitoring/` - Observabilidade
- Configurações e assets para Prometheus, Grafana e logging
- Preparado para integração com stack ELK ou Fluentd

### `/backup/` - Estratégia de Backup
- Scripts e diretórios para backups manuais e automáticos
- Estrutura por serviço para facilitar restauração seletiva

### `/docs/` - Documentação
- Guias técnicos, decisões arquiteturais e documentação de API
- Ajuda a manter o conhecimento acessível e versionado

### `/tests/` - Testes
- Base para automação de testes de integração, carga e smoke
- Pode ser expandido com frameworks como Postman, k6, etc.

## Arquivos Importantes na Raiz

### `.env.example`
Template das variáveis de ambiente necessárias

### `Makefile`
Comandos úteis para gerenciar o stack:
```makefile
.PHONY: up down restart logs backup

up:
	docker-compose up -d

down:
	docker-compose down

restart:
	docker-compose restart

logs:
	docker-compose logs -f

backup:
	./scripts/backup.sh

setup:
	./scripts/setup.sh
```

### `.gitignore`
```gitignore
.env
secrets/
data/
backup/
*.log
.DS_Store
```

## Benefícios desta Estrutura

1. **Organização Clara**: Cada tipo de arquivo tem seu lugar
2. **Segurança**: Secrets separados e excluídos do controle de versão
3. **Manutenibilidade**: Fácil localização e modificação de configurações
4. **Escalabilidade**: Estrutura preparada para crescimento
5. **Backup**: Estratégia clara de backup por componente
6. **Documentação**: Local dedicado para documentação técnica
7. **Automação**: Scripts organizados para operações comuns
8. **Monitoramento**: Preparado para observabilidade
