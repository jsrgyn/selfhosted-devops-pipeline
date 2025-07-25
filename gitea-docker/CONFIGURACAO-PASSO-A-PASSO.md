# 🚀 DevOps Stack - Guia de Configuração Completo

Este guia detalha como configurar e integrar todos os serviços do DevOps Stack com OAuth2 e Webhooks.

## 📋 Pré-requisitos

- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM mínimo
- 20GB espaço em disco

## 🛠️ Passo 1: Preparação do Ambiente

### 1.1 Clonar/Preparar Arquivos

```bash
# Criar diretório do projeto
mkdir devops-stack && cd devops-stack

# Copiar todos os arquivos fornecidos:
# - docker-compose.yml
# - .env
# - init-postgres.sql
# - nginx/nginx.conf
# - nginx/conf.d/devops.conf
# - nginx/html/dashboard/index.html
# - setup.sh
```

### 1.2 Executar Setup Automatizado

```bash
chmod +x setup.sh
./setup.sh
```

O script irá:

- ✅ Verificar dependências
- ✅ Gerar tokens seguros
- ✅ Configurar hosts file
- ✅ Criar diretórios necessários
- ✅ Iniciar todos os serviços

## 🔧 Passo 2: Configuração Initial do Gitea

### 2.1 Acessar Gitea pela primeira vez

1. Abra: http://devops.local/gitea
2. Complete o formulário de instalação inicial:
   - **Tipo de Banco**: PostgreSQL
   - **Host**: postgres_dbx:5432
   - **Usuário**: user_gitea
   - **Senha**: 12345678gitea
   - **Nome do Banco**: gitea
   - **URL Base**: http://devops.local/gitea/
   - **Porta SSH**: 2222

### 2.2 Criar Usuário Administrador

1. Defina um usuário admin (ex: admin)
2. Senha forte (ex: Admin@123456)
3. Email válido

### 2.3 Configurar OAuth2 para Drone

1. Login como admin
2. Ir em **Settings** → **Applications**
3. Criar nova **OAuth2 Application**:
   - **Application Name**: Drone CI
   - **Redirect URI**: `http://drone.local/login`
   - **Client ID**: (será gerado - anote!)
   - **Client Secret**: (será gerado - anote!)

## 🔄 Passo 3: Configuração do Drone CI

### 3.1 Atualizar Credenciais OAuth2

Edite o arquivo `.env` com os dados do OAuth2:

```bash
# Substitua pelos valores reais obtidos do Gitea
DRONE_GITEA_CLIENT_ID=sua-aplicacao-client-id-aqui
DRONE_GITEA_CLIENT_SECRET=sua-aplicacao-client-secret-aqui
```

### 3.2 Reiniciar Drone

```bash
docker-compose restart drone-server drone-runner
```


Aguarde todos os serviços ficarem saudáveis (docker-compose ps).
Abra o navegador e acesse http://gitea.local/ (sem /gitea/).
Você será apresentado à página de instalação do Gitea. Isso prova que o reset funcionou.
Confirme se a "URL Base da Aplicação" na página de instalação é http://gitea.local/.
Complete a instalação e crie sua conta de administrador.
Após a instalação, você estará no dashboard em http://gitea.local/. Todos os links internos (para repositórios, configurações, etc.) agora serão gerados corretamente, sem o /gitea/ extra.
Agora, vá para Configurações -> Aplicações e crie a aplicação OAuth2 para o Drone. A URI de Redirecionamento deve ser http://drone.local/login.
Copie o Client ID e Secret para o seu arquivo .env.
Reinicie apenas o Drone para que ele pegue as novas credenciais:
Generated bash
docker-compose restart drone-server
Use code with caution.
Bash
Por fim, acesse http://drone.local/ e complete o fluxo de autorização.

### 3.3 Acessar Drone

1. Abra: http://devops.local/drone
2. Clique em **Login with Gitea**
3. Autorize a aplicação no Gitea
4. Você será redirecionado de volta ao Drone logado

## 🔗 Passo 4: Configurar Webhooks

### 4.1 Webhook Automático (Recomendado)

O Drone pode configurar webhooks automaticamente:

1. No Drone, ative um repositório
2. O webhook será criado automaticamente no Gitea

### 4.2 Webhook Manual (se necessário)

No Gitea, para cada repositório:

1. **Settings** → **Webhooks**
2. **Add Webhook** → **Gitea**
3. Configurar:
   - **Target URL**: `http://devops.local/drone/hook`
   - **HTTP Method**: POST
   - **POST Content Type**: application/json
   - **Secret**: (valor de DRONE_WEBHOOK_SECRET do .env)
   - **Trigger On**: Push events, Pull request events

## 📊 Passo 5: Configuração do SonarQube

### 5.1 Acesso Inicial

1. Abra: http://devops.local/sonarqube
2. Login padrão: admin/admin
3. Altere a senha imediatamente

### 5.2 Gerar Token para Integração

1. **Administration** → **Security** → **Users**
2. Clique no usuário admin → **Tokens**
3. **Generate Token**:
   - **Name**: Drone Integration
   - **Type**: Global Analysis Token
   - **Expires**: Never (ou conforme política)
4. **Anote o token gerado!**

### 5.3 Configurar Qualidade Gate Webhook (Opcional)

Para notificações de volta ao Drone:

1. **Administration** → **Configuration** → **Webhooks**
2. **Create**:
   - **Name**: Drone Webhook
   - **URL**: `http://devops.local/drone/hook/sonar`
   - **Secret**: (mesmo valor do DRONE_WEBHOOK_SECRET)

## 🔄 Passo 6: Exemplo de Pipeline Drone

Crie um arquivo `.drone.yml` no seu repositório:

```yaml
kind: pipeline
type: docker
name: default

steps:
  # Teste unitário
  - name: test
    image: node:18-alpine
    commands:
      - npm install
      - npm test
```

Teste no Navegador (Limpe o Cache!):
Acesse: http://sonar.local -> Isto deve funcionar agora.
Acesse: http://localhost/gitea/ -> Deve continuar funcionando.
Acesse: http://localhost/drone/ -> Deve continuar funcionando.
Acesse: http://localhost/quality -> Deve te redirecionar para http://sonar.local.

Sr. Johnathan, para editar o arquivo /etc/hosts no macOS e adicionar a entrada 127.0.0.1 sonar.local, siga este passo a passo:

⸻

🛠️ Como editar o /etc/hosts no macOS
	1.	Abra o Terminal
Pressione Command + Space, digite Terminal e pressione Enter.
	2.	Edite o arquivo como superusuário
Execute o seguinte comando para abrir o arquivo com permissões de edição:

sudo nano /etc/hosts


	3.	Adicione a linha no final do arquivo
No final do arquivo, adicione:

127.0.0.1    sonar.local
127.0.0.1    drone.local
127.0.0.1    drone.local sonar.local gitea.local
127.0.0.1 gitea.local drone.local sonar.local

⚠️ Cuidado para não remover ou alterar outras linhas existentes, como a do localhost.

	4.	Salve o arquivo no nano
	•	Pressione Control + O (para salvar)
	•	Pressione Enter (para confirmar)
	•	Pressione Control + X (para sair)
	5.	(Opcional) Limpe o cache de DNS
Para garantir que a mudança seja reconhecida imediatamente:

sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder


	6.	Teste a configuração
Você pode testar com:

ping sonar.local

Ou acessar no navegador:
http://sonar.local

⸻

Se estiver usando Docker e o sonar.local estiver mapeado no Nginx como proxy reverso, a entrada no /etc/hosts será essencial para o navegador localizar o serviço corretamente.

Se precisar que esse domínio também funcione em containers ou em outro dispositivo da rede, posso te ajudar com DNS interno ou mapeamento em outros hosts.


Passo 1: Criar a Aplicação OAuth2 no Gitea

Acesse seu Gitea no navegador: http://localhost/gitea/.
Faça login com a conta de administrador.
Vá para Configurações (clicando no seu avatar no canto superior direito).
No menu lateral, vá para Aplicações.
Clique em Gerenciar Aplicações OAuth2 e depois em Adicionar Aplicação.
Preencha o formulário:
Nome da Aplicação: Drone CI (ou o que preferir).
URI de Redirecionamento: Este é o ponto mais crítico. A URI deve ser a URL completa do seu Drone, seguida por /login.
Valor correto: http://drone.local/login
Clique em Adicionar Aplicação.
O Gitea vai te mostrar um ID do Cliente e um Segredo do Cliente. Copie esses dois valores. Eles só são mostrados uma vez.
Passo 2: Atualizar o arquivo .env

Agora, abra seu arquivo .env e substitua os placeholders pelos valores que você copiou do Gitea.

Generated env
# .env

# ...

# OAuth2 com Gitea
DRONE_GITEA_SERVER=http://gitea_x:3000
DRONE_GITEA_CLIENT_ID=COLE_O_ID_DO_CLIENTE_AQUI
DRONE_GITEA_CLIENT_SECRET=COLE_O_SEGREDO_DO_CLIENTE_AQUI

# ...
Use code with caution.
Env
Passo 3: Corrigir e Simplificar a Configuração do Drone no docker-compose.yml

O healthcheck está mais atrapalhando do que ajudando. Vamos removê-lo. Além disso, vamos garantir que o Drone se comunique corretamente com o Gitea.

No seu docker-compose.yml, no serviço drone-server:

Generated yaml
# docker-compose.yml

  drone-server:
    image: drone/drone:2.20
    container_name: drone_server
    restart: unless-stopped
    environment:
      # Drone Settings - CORREÇÃO CRÍTICA ABAIXO
      - DRONE_GITEA_SERVER=http://gitea_x:3000  # Comunicação interna, nome do serviço está correto
      - DRONE_GITEA_CLIENT_ID=${DRONE_GITEA_CLIENT_ID}
      - DRONE_GITEA_CLIENT_SECRET=${DRONE_GITEA_CLIENT_SECRET}
      - DRONE_RPC_SECRET=${DRONE_RPC_SECRET}
      - DRONE_RPC_HOST=drone-server # Nome do serviço para o runner se conectar
      # Esta configuração define a URL PÚBLICA do seu Drone
      - DRONE_SERVER_HOST=localhost 
      - DRONE_SERVER_PROTO=http
      - DRONE_LOGS_PRETTY=true
      - DRONE_LOGS_COLOR=true
      # Database
      - DRONE_DATABASE_DRIVER=postgres
      - DRONE_DATABASE_DATASOURCE=postgres://${DRONE_DATABASE_USER}:${DRONE_DATABASE_PASSWORD}@postgres_dbx:5432/${DRONE_DATABASE}?sslmode=disable
      # User
      - DRONE_USER_CREATE=username:${DRONE_ADMIN_USER},admin:true
    networks:
      - gitea-network
    volumes:
      - drone_data:/data
    depends_on:
      postgres_dbx:
        condition: service_healthy
      gitea:
        condition: service_healthy
    # REMOVA O BLOCO HEALTHCHECK INTEIRO
    # healthcheck:
    #   ...


    http://drone.local/login


Teste tudo no navegador (limpe o cache):
http://localhost/gitea/ -> Deve funcionar.
http://sonar.local/ -> Deve funcionar.
http://drone.local/ -> Deve funcionar.


Teste o Fluxo Limpo:
Acesse http://gitea.local/ e complete a instalação do Gitea.
Verifique a App OAuth no Gitea. A URI de Redirecionamento deve ser http://drone.local/login.
Acesse http://drone.local/ e faça o login.

mkdir -p ./ssh
ssh-keygen -t rsa -b 4096 -f ./ssh/id_rsa -N ''


-----------------

com o comando:
docker network inspect devops-network    
verificar a faixa do IP e ajustar as faixa do 
extra_hosts:
    #  - "host.docker.internal:host-gateway"
    #  - "gitea.local:172.20.0.1" # Use o IP do Nginx ou do Host Gateway
    #  - "drone.local:172.20.0.1"
    #  - "sonar.local:172.20.0.1"
Ajustar o APP.ini do gitea para aceitar conexão por traz de um proxy 
; Confia nos cabeçalhos enviados pelo Nginx
ENABLE_REVERSE_PROXY_AUTHENTICATION = true
ENABLE_REVERSE_PROXY_AUTO_REGISTRATION = true
ENABLE_REVERSE_PROXY_EMAIL = true
REVERSE_PROXY_TRUSTED_PROXIES = 172.16.0.0/12,192.168.0.0/16,10.0.0.0/8
e
DOMAIN           = ${GITEA_DOMAIN}
HTTP_PORT        = 3000
#ROOT_URL         = http://${GITEA_DOMAIN}:${GITEA_HTTP_PORT}/
ROOT_URL         = http://${GITEA_DOMAIN}
PROTOCOL         = http