# Troubleshooting Guide - DevOps Stack

## Sumário
1. [Problemas Gerais](#problemas-gerais)  
2. [Gitea](#gitea)  
3. [Drone Server](#drone-server)  
4. [Drone Runner SSH](#drone-runner-ssh)  
5. [Build Server Node](#build-server-node)  
6. [SonarQube](#sonarqube)  
7. [PostgreSQL](#postgresql)  
8. [Nginx](#nginx)  
9. [Ferramentas Úteis](#ferramentas-úteis)

---

## Problemas Gerais
### Serviços não iniciam
```bash
# Verificar status dos containers
docker-compose ps

# Verificar logs gerais
docker-compose logs --tail=100
```

### Problemas de Rede
```bash
# Testar comunicação entre containers
docker exec -it gitea ping drone_server
docker exec -it drone_server ping postgres_dbx

# Inspecionar rede
docker network inspect devops-network
```

### Variáveis de Ambiente
```bash
# Verificar se as variáveis estão carregadas
docker-compose config | grep -E 'DRONE_|GITEA_|POSTGRES_'

# Validar substituições
docker exec gitea env | grep GITEA__
```

---

## Gitea
### Falha na Inicialização
```bash
docker logs gitea | grep -i error
```

**Causas Comuns:**  
1. Conexão com PostgreSQL:  
   ```bash
   docker exec -it postgres_dbx psql -U ${POSTGRES_USER} -d gitea
   ```
2. Permissões de volume:  
   ```bash
   chown -R ${USER_UID}:${USER_GID} ./data/gitea
   ```
3. Secrets inválidos (gerar novos):  
   ```bash
   openssl rand -hex 32
   ```

### Acesso Web Não Funciona
```bash
curl -I http://localhost:${GITEA_HTTP_PORT}
```

**Soluções:**  
- Verificar `GITEA__server__ROOT_URL` no .env
- Validar configuração do Nginx (proxy reverso)

---

## Drone Server
### Autenticação com Gitea Falha
```bash
docker logs drone_server | grep -i 'gitea login'
```

**Passos para Resolver:**  
1. Verificar no Gitea: `Settings -> Applications`  
2. Validar callback URL: `http://drone.local/login`  
3. Confirmar variáveis no .env:  
   - `DRONE_GITEA_SERVER`  
   - `DRONE_GITEA_CLIENT_ID`  
   - `DRONE_GITEA_CLIENT_SECRET`

### Conexão com PostgreSQL
```bash
docker exec drone_server \
  curl -s "postgres://${DRONE_DATABASE_USER}:${DRONE_DB_PASSWORD}@postgres_dbx:5432/drone"
```

---

## Drone Runner SSH
### Runner Não Registrado
```bash
docker logs drone_runner_ssh | grep -i 'register'
```

**Verificar:**  
1. `DRONE_RPC_SECRET` igual no server e runner  
2. `DRONE_RPC_HOST` apontando para `drone_server`  
3. Labels correspondentes no pipeline:  
   ```yaml
   kind: pipeline
   type: ssh
   ```

### Falha em Executar Pipelines
```bash
docker exec drone_runner_ssh cat /root/.ssh/authorized_keys
```
**Solução:**  
Montar chave SSH correta no volume:  
```yaml
volumes:
  - ./secrets/ssh/id_rsa.pub:/root/.ssh/authorized_keys:ro
```

---

## Build Server Node
### SSH Inacessível
```bash
# Testar conexão
ssh -p 8022 root@localhost
```

**Resolver:**  
1. Descomentar porta no compose:  
   ```yaml
   ports:
     - "8022:22"
   ```
2. Verificar permissão da chave:  
   ```bash
   chmod 600 ./secrets/ssh/id_rsa
   ```

### Builds Falhando
```bash
docker exec build_server_node tail -f /root/builds/*.log
```
**Verificar:**  
- Espaço em disco: `df -h /root/builds`  
- Permissões do volume: `chown -R 1000:1000 ./data/build-server`

---

## SonarQube
### Health Check Falhando
```bash
docker logs sonarqube | grep -i 'status'
```

**Causas:**  
1. PostgreSQL não acessível  
2. Permissões de volume:  
   ```bash
   chown -R 1000:1000 ./data/sonarqube
   ```
3. Memória insuficiente:  
   ```yaml
   ulimits:
     memlock: -1
   ```

### Análises Falhando
```bash
docker exec sonarqube cat /opt/sonarqube/logs/*.log
```
**Solução:**  
Atualizar scanner no Dockerfile:  
```Dockerfile
RUN wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-latest-linux.zip
```

---

## PostgreSQL
### Banco Não Inicializado
```bash
docker logs postgres_dbx | grep 'init-scripts'
```

**Verificar:**  
1. Script de inicialização:  
   ```bash
   ./config/postgres/init-scripts/01-init-databases.sh
   ```
2. Permissões de execução:  
   ```bash
   chmod +x ./config/postgres/init-scripts/*.sh
   ```

### Conexões Recusadas
```bash
docker exec postgres_dbx netstat -tulpn | grep 5432
```
**Resolver:**  
- Validar mapping de porta:  
  ```yaml
  ports:
    - "${POSTGRES_PORT:-5432}:5432"
  ```

---

## Nginx
### Domínios Não Resolvidos
```bash
docker exec nginx nginx -T | grep server_name
```

**Configuração Recomendada:**  
```nginx
server {
  server_name gitea.local;
  location / {
    proxy_pass http://gitea:3000;
  }
}
```

### SSL Não Funciona
```bash
docker exec nginx ls -la /etc/nginx/ssl
```
**Pré-requisitos:**  
1. Certificados no host: `./config/nginx/ssl/`  
2. Configuração no compose:  
   ```yaml
   volumes:
     - ./config/nginx/ssl:/etc/nginx/ssl:ro
   ```

---

## Ferramentas Úteis
### Comandos de Diagnóstico
```bash
# Verificar consumo de recursos
docker stats

# Testar conectividade entre serviços
docker run --rm --network devops-network appropriate/curl \
  curl -I http://gitea:3000

# Entrar em container
docker exec -it gitea sh
```

### Geração de Secrets
```bash
# Gerar novos secrets
for item in KEY SECRET TOKEN; do
  echo "GITEA_${item}=$(openssl rand -hex 32)" >> .env
done
```

### Limpeza de Sistema
```bash
# Remover containers parados
docker-compose down --remove-orphans

# Limpar volumes não utilizados
docker volume prune
```

> **Nota:** Sempre valide as permissões de arquivos e variáveis de ambiente após atualizações