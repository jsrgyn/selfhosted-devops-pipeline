# Guia de Configuração de Projetos na Stack DevOps

## Visão Geral

Este guia detalha o processo completo de configuração de um novo projeto na stack DevOps local, incluindo integração com Gitea, Drone CI e SonarQube.

## 1. Preparação do Ambiente

### 1.1. Geração de Chaves SSH

Execute o comando para gerar par de chaves SSH (caso não existam):

```bash
ssh-keygen -t rsa -b 4096 -f ./secrets/ssh/id_rsa -q -N ''
```

**Verificação:** Confirme que as chaves foram criadas:
```bash
ls -la ./secrets/ssh/
# Deve mostrar: id_rsa (privada) e id_rsa.pub (pública)
```

## 2. Configuração do Gitea

### 2.1. Criação de Usuários e Repositório

1. **Acesso Administrativo**:
   - Primeiro usuário criado no Gitea será automaticamente administrador
   - Acesse: http://gitea.local

2. **Criação de Usuários Comuns**:
   - Como administrador, vá em "Site Administration" → "Users" → "Create User"
   - Preencha os dados do usuário comum

3. **Criação do Repositório**:
   - Faça login com usuário administrador ou comum
   - Clique em "+" → "New Repository"
   - Nome: `calculadora-api`
   - Descrição: Projeto de exemplo para testes CI/CD
   - Inicializar com README: ✅ Marcar

### 2.2. Commit Inicial do Projeto

Navegue até a pasta do projeto e execute:

```bash
# Acesse a pasta do projeto
cd ./prj_teste/calculadora-api

# Remove repositório anterior se existir
rm -rf .git

# Inicializa novo repositório
git init
git checkout -b main

# Configura usuário (substitua com seus dados)
git config user.email "usuario@example.com"
git config user.name "Seu Nome"

# Primeiro commit
git add .
git commit -m "first commit"

# Adiciona remote e faz push
git remote add origin http://gitea.local/usuario/calculadora-api.git
git push -u origin main
```

### 2.3. Proteção da Branch Main

1. Acesse o repositório no Gitea
2. Vá em "Settings" → "Branches"
3. Em "Branch Protection Rules", adicione proteção para `main`:

**Configurações de Proteção:**
- ✅ Enable Branch Protection
- ✅ Require pull request reviews before merging
- ✅ Dismiss stale pull request approvals
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging

**Approval Rules:**
- Required approvals: `2` (mínimo um revisor)

**Status Checks:**
- Adicione os checks obrigatórios:
  - `continuous-integration/drone/push`
  - `continuous-integration/drone/pr`

## 3. Configuração do SonarQube

### 3.1. Criação do Projeto e Token

1. **Acesso ao SonarQube**:
   - URL: http://sonar.local
   - Credenciais: admin/admin (alterar após primeiro login)

2. **Criação do Projeto**:
   - Navegue para "Projects" → "Create Project"
   - Selecione "Manually"
   - Preencha os dados:
     - Project display name: `API da Calculadora`
     - Project key: `calculadora-api` (deve coincidir com sonar-project.properties)

3. **Geração do Token**:
   - Vá para sua conta → "Security" → "Tokens"
   - Generate new token:
     - Name: `droneci-calculadora-api-token`
     - Type: `Global Analysis Token`
   - **Importante**: Copie e guarde o token em local seguro

## 4. Configuração do Drone CI

### 4.1. Sincronização do Projeto

1. **Acesso ao Drone CI**:
   - URL: http://drone.local
   - Faça login com sua conta do Gitea

2. **Ativação do Repositório**:
   - No Drone CI, clique em "Sync" para atualizar lista de repositórios
   - Encontre o repositório `calculadora-api`
   - Clique para ativar o repositório

### 4.2. Configuração de Secrets

Acesse as configurações do repositório no Drone CI → "Secrets"

#### 4.2.1. SSH para Build Server
```yaml
Name: BUILD_SERVER_SSH_KEY
Value: [conteúdo completo da chave privada id_rsa]
Allow Pull Request: ✅
```

#### 4.2.2. Token do SonarQube
```yaml
Name: SONAR_TOKEN
Value: [token gerado no SonarQube]
Allow Pull Request: ✅
```

#### 4.2.3. URL do SonarQube
```yaml
Name: SONAR_HOST_URL
Value: http://sonar.local
Allow Pull Request: ✅
```

### 4.3. Configuração de Webhook

**Automática (Recomendado):**
- A ativação do repositório no Drone cria automaticamente o webhook no Gitea
- Verifique em: Gitea → Repository Settings → Webhooks

**Manual (Caso Necessário):**
1. No Drone CI, vá em Repository Settings → Webhooks
2. Gere um secret manualmente
3. No Gitea, vá em Repository Settings → Webhooks → Add Webhook:
   ```
   URL: http://drone.local/hook
   Method: POST
   Secret: [secret gerado no Drone]
   Events: Push, Pull Request, Tag
   Active: ✅
   ```

### 4.4. Configuração do sonar-project.properties

Verifique se o projeto possui o arquivo `sonar-project.properties` na raiz:

```properties
# sonar-project.properties
sonar.projectKey=calculadora-api
sonar.projectName=API da Calculadora
sonar.projectVersion=1.0

sonar.sources=src
sonar.tests=test
sonar.sourceEncoding=UTF-8
sonar.host.url=http://sonar.local

# Configurações específicas da linguagem
sonar.language=js
sonar.javascript.lcov.reportPaths=coverage/lcov.info
```

## 5. Pipeline de Exemplo (.drone.yml)

Crie o arquivo `.drone.yml` na raiz do projeto:

```yaml
kind: pipeline
type: ssh
name: calculadora-api-ci

trigger:
  event: [push, pull_request]

server:
  host: build-server-node
  user: root
  ssh_key:
    from_secret: BUILD_SERVER_SSH_KEY

steps:
  - name: install-dependencies
    commands:
      - npm install
      - npm run build

  - name: run-tests
    commands:
      - npm test
      - npm run coverage

  - name: sonarqube-analysis
    commands:
      - sonar-scanner
    environment:
      SONAR_TOKEN:
        from_secret: SONAR_TOKEN
      SONAR_HOST_URL:
        from_secret: SONAR_HOST_URL

  - name: deploy-to-test
    commands:
      - npm run deploy:test
    when:
      event: push
      branch: main
```

## 6. Teste da Configuração

### 6.1. Primeiro Push com Pipeline

```bash
git add .drone.yml
git commit -m "Add CI/CD pipeline"
git push origin main
```

### 6.2. Verificação dos Resultados

1. **Drone CI**: Acesse http://drone.local para ver o status do pipeline
2. **SonarQube**: Acesse http://sonar.local para ver a análise de código
3. **Teste da API**: Acesse o endpoint para verificar funcionamento:
   ```
   http://localhost:8000/api/sum?a=5&b=3
   ```

## 7. Solução de Problemas Comuns

### 7.1. Webhook Não Funciona
```bash
# Verificar logs do Drone
docker-compose logs drone-server

# Testar webhook manualmente no Gitea
# Gitea → Repository Settings → Webhooks → Test Delivery
```

### 7.2. Falha de Autenticação SSH
```bash
# Verificar se a chave foi adicionada corretamente
docker-compose exec build-server-node cat /root/.ssh/authorized_keys
```

### 7.3. SonarQube Não Recebe Dados
```bash
# Verificar se o token está correto
echo $SONAR_TOKEN

# Testar conexão com SonarQube
curl -u ${SONAR_TOKEN}: http://sonar.local/api/system/status
```

## 8. Próximos Passos

- Configurar notificações (Slack, Email) para resultados de pipeline
- Implementar deployment automático para produção
- Configurar monitoramento da aplicação no Grafana
- Adicionar testes de segurança no pipeline (Trivy, OWASP ZAP)

---

**Nota:** Este guia assume que a stack DevOps já está configurada e funcionando. Para problemas de infraestrutura, consulte o guia de configuração da stack.