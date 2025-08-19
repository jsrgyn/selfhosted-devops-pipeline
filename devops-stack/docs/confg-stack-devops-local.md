# Configuração da Stack DevOps Local - Guia Completo

## Visão Geral

Este guia detalha o processo de configuração e integração dos principais componentes da stack DevOps local: Gitea (Git server), Drone CI (pipeline CI/CD) e SonarQube (análise de qualidade de código).

## Pré-requisitos

- Docker e Docker Compose instalados
- Arquivo `hosts` configurado com os domínios locais
- Arquivo `.env` configurado com as variáveis de ambiente

## 1. Preparação do Ambiente

### 1.1. Reset do Ambiente (Opcional)

Execute o script de limpeza para garantir um ambiente limpo:

```bash
./reset_clear.sh
```

**Nota:** Este script irá parar e remover containers, volumes e redes existentes. Use com cuidado em ambientes de produção.

### 1.2. Inicialização dos Serviços

Inicie todos os serviços da stack DevOps:

```bash
docker-compose --env-file .env up -d
```

Verifique o status dos serviços:

```bash
docker-compose ps
```

## 2. Configuração do Gitea

### 2.1. Acesso Inicial

Acesse o Gitea em: [http://gitea.local](http://gitea.local)

### 2.2. Criação de Conta de Usuário

1. Clique em "Register" no canto superior direito
2. Preencha os dados necessários:
   - Nome de usuário
   - Email válido
   - Senha segura
3. Complete o registro

### 2.3. Configuração como Administrador (Opcional)

Se necessário, faça login com as credenciais de administrador definidas no arquivo `.env`:

- Usuário: `admin`
- Senha: Definida em `GITEA_ADMIN_PASSWORD` (se configurado)

## 3. Configuração do OAuth2 para Integração com Drone CI

### 3.1. Acesso às Configurações do Gitea

1. Faça login no Gitea
2. Acesse as configurações do usuário clicando em sua foto de perfil → "Settings"

### 3.2. Criação da Aplicação OAuth2

1. Navegue até a seção "Applications" no menu lateral
2. Clique em "Create New Application"
3. Preencha os campos obrigatórios:

   | Campo | Valor |
   |-------|-------|
   | Application Name | `Drone CI` |
   | Redirect URI | `http://drone.local/login` |

4. Clique em "Create Application"

### 3.3. Obtenção das Credenciais

1. Após criar a aplicação, anote os valores gerados:
   - **Client ID**
   - **Client Secret**

2. Mantenha estas informações seguras - elas serão usadas para configurar o Drone CI

## 4. Configuração do Drone CI

### 4.1. Atualização das Variáveis de Ambiente

Edite o arquivo `.env` e atualize as seguintes variáveis com as credenciais obtidas:

```env
DRONE_GITEA_CLIENT_ID=seu-client-id-aqui
DRONE_GITEA_CLIENT_SECRET=seu-client-secret-aqui
```

### 4.2. Reinicialização dos Serviços

Aplique as novas configurações reiniciando os serviços:

```bash
docker-compose --env-file .env up -d
```

### 4.3. Primeiro Acesso ao Drone CI

1. Acesse o Drone CI em: [http://drone.local](http://drone.local)
2. Faça login usando sua conta do Gitea
3. Autorize o Drone CI a acessar sua conta quando solicitado

### 4.4. Ativação de Repositórios

1. No Drone CI, navegue até a seção "Repositories"
2. Ative o sync para sincronizar seus repositórios
3. Ative os repositórios que deseja integrar com CI/CD

## 5. Configuração do SonarQube

### 5.1. Acesso Inicial

Acesse o SonarQube em: [http://sonar.local](http://sonar.local)

### 5.2. Login Inicial

Use as credenciais padrão:
- **Usuário**: `admin`
- **Senha**: `admin`

### 5.3. Alteração de Senha (Recomendado)

1. Após o primeiro login, navegue até sua conta
2. Vá para "Security" 
3. Altere a senha padrão por uma senha segura

### 5.4. Criação de Token de Acesso

1. Acesse sua conta → "Security"
2. Na seção "Tokens", gere um novo token
3. Atribua um nome descritivo (ex: "drone-ci-integration")
4. Copie e guarde o token gerado - ele será necessário para integração com o Drone CI

## 6. Verificação da Configuração

### 6.1. Teste de Acesso aos Serviços

Verifique se todos os serviços estão acessíveis:

| Serviço | URL | Status Esperado |
|---------|-----|-----------------|
| Gitea | http://gitea.local | Login funcionando |
| Drone CI | http://drone.local | Login via Gitea funcionando |
| SonarQube | http://sonar.local | Dashboard acessível |

### 6.2. Teste de Integração

1. Crie um novo repositório no Gitea
2. Adicione um arquivo `.drone.yml` básico
3. Faça push para o repositório
4. Verifique se o Drone CI detecta automaticamente o novo commit

## 7. Solução de Problemas Comuns

### 7.1. Problemas de Conexão

```bash
# Verificar logs dos serviços
docker-compose logs gitea
docker-compose logs drone-server
docker-compose logs sonarqube

# Verificar status dos containers
docker-compose ps

# Verificar conectividade de rede
docker-compose exec drone-server ping gitea.local
```

### 7.2. Problemas de Autenticação OAuth2

1. Verifique se o "Redirect URI" no Gitea está exatamente como `http://drone.local/login`
2. Confirme se as variáveis `DRONE_GITEA_CLIENT_ID` e `DRONE_GITEA_CLIENT_SECRET` estão corretas
3. Reinicie os serviços após qualquer alteração

### 7.3. SonarQube Lento para Iniciar

O SonarQube pode levar vários minutos para iniciar completamente. Verifique os logs:

```bash
docker-compose logs --follow sonarqube
```

## 8. Próximos Passos

### 8.1. Configuração de Pipeline Básico

Crie um arquivo `.drone.yml` de exemplo:

```yaml
kind: pipeline
type: docker
name: default

steps:
- name: test
  image: node:18
  commands:
  - npm install
  - npm test

- name: sonarqube
  image: sonarsource/sonar-scanner-cli
  commands:
  - sonar-scanner
  environment:
    SONAR_HOST_URL: http://sonar.local
    SONAR_TOKEN: seu-sonar-token-aqui
```

### 8.2. Configuração de Webhooks Automáticos

Os webhooks entre Gitea e Drone CI são configurados automaticamente durante a ativação do repositório.

### 8.3. Monitoramento da Stack

Acesse o Grafana em [http://grafana.local](http://grafana.local) para monitorar o desempenho da stack.

## 9. Considerações de Segurança

1. Altere todas as senhas padrão após a primeira configuração
2. Utilize tokens de acesso em vez de senhas para integrações
3. Revise regularmente as permissões OAuth2 no Gitea
4. Mantenha os serviços atualizados com as últimas versões de segurança

## Suporte

Em caso de problemas:
1. Consulte os logs dos serviços com `docker-compose logs [serviço]`
2. Verifique a documentação oficial de cada projeto
3. Consulte as issues no repositório do projeto

---

**Nota:** Este guia assume uma configuração local para desenvolvimento e testes. Para ambientes de produção, implemente medidas adicionais de segurança e considere utilizar certificados SSL válidos.