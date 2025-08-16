# Runbook: Restauração de Backup

## Objetivo
Este runbook guia o processo de restauração de um backup completo do ambiente DevOps.

## Pré-requisitos
- Acesso SSH ao servidor
- Permissões de sudo
- Arquivo de backup disponível em `/backup/restore/latest`

## Passo a Passo

### 1. Parar serviços dependentes
```bash
docker-compose down
```

### 2. Restaurar volumes
```bash
cd /path/to/devops-stack
./restore/restore-volumes.sh /backup/restore/latest
```

### 3. Restaurar banco de dados
```bash
./restore/restore-postgres.sh /backup/restore/latest
```

### 4. Iniciar serviços
```bash
docker-compose up -d
```

### 5. Verificar integridade
```bash
docker-compose ps
curl http://localhost/health
```

## Notas
- Tempo estimado: 30 minutos
- Impacto: Indisponibilidade total durante o processo