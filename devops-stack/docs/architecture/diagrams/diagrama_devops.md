# Diagrama de Arquitetura - DevOps Stack

```mermaid
graph TD
    subgraph Docker Host
        subgraph devops-network[DevOps Network - 172.20.0.0/16]
            nginx[Nginx]
            gitea[Gitea]
            drone_server[Drone Server]
            drone_runner[Drone Runner SSH]
            build[Build Server]
            sonarqube[Sonarqube]
            postgres[PostgreSQL]
        end
    end

    User[Usuário] -->|HTTP/HTTPS| nginx
    
    nginx -->|Proxy| gitea
    nginx -->|Proxy| drone_server
    nginx -->|Proxy| sonarqube
    
    gitea -->|JDBC| postgres
    drone_server -->|SQL| postgres
    sonarqube -->|JDBC| postgres
    
    drone_server -->|gRPC| drone_runner
    drone_runner -->|SSH| build
    
    build -->|Analisa| sonarqube
    build -->|Push/Pull| gitea

    classDef proxy fill:#f96,color:#fff;
    classDef service fill:#4db6ac,color:#fff;
    classDef db fill:#7986cb,color:#fff;
    classDef runner fill:#64b5f6,color:#fff;
    classDef user fill:#81c784,color:#000;
    
    class nginx proxy;
    class gitea,drone_server,sonarqube service;
    class postgres db;
    class drone_runner,build runner;
    class User user;
```

## Legenda do Diagrama

### Componentes Principais
1. **Nginx** (Proxy Reverso)
   - Roteamento para serviços
   - Terminação SSL
   - Balanceamento de carga

2. **Gitea** (Git Server)
   - Versionamento de código
   - Gerenciamento de repositórios
   - Integração com CI/CD

3. **Drone Server** (CI/CD Controller)
   - Orquestração de pipelines
   - Gerenciamento de builds
   - Integração com Gitea

4. **Drone Runner SSH** (CI/CD Executor)
   - Execução de jobs
   - Comunicação com Build Server
   - Escalonamento de tarefas

5. **Build Server** (Ambiente de Execução)
   - Execução de pipelines
   - Ferramentas de build (Node.js, SonarScanner)
   - Ambiente isolado

6. **SonarQube** (Análise de Qualidade)
   - Inspeção contínua de código
   - Métricas de qualidade
   - Detecção de vulnerabilidades

7. **PostgreSQL** (Banco de Dados Central)
   - Armazenamento para Gitea, Drone e SonarQube
   - Persistência de dados
   - Gerenciamento transacional

### Fluxos de Comunicação
```mermaid
flowchart LR
    A[Usuário] --> B[Nginx]
    B --> C[Serviços]
    D[CI/CD] --> E[Builds]
    F[Repositórios] --> G[Análise]
    
    subgraph Comunicações
        B <-.Proxy Reverso.-> C
        D <-.Orquestração.-> E
        F <-.Webhooks.-> G
    end
```

## Padrões de Projeto Implementados

### 1. Proxy Pattern (Nginx)
- **Função**: Atuar como facade para serviços internos
- **Benefícios**:
  - Unificação de acesso
  - Segurança adicional
  - Gerenciamento centralizado de TLS

### 2. Repository Pattern (Gitea + PostgreSQL)
- **Implementação**:
  ```mermaid
  classDiagram
      class GitRepository {
          +push()
          +pull()
          +webhook()
      }
      class Database {
          +store()
          +retrieve()
      }
      GitRepository --> Database : Persists
  ```
- **Benefícios**: Separação entre armazenamento e lógica de negócios

### 3. CI/CD Pipeline Pattern
```mermaid
sequenceDiagram
    participant G as Gitea
    participant D as Drone Server
    participant R as Drone Runner
    participant B as Build Server
    
    G->>D: Webhook (Push Event)
    D->>R: Assign Job
    R->>B: SSH Command
    B->>B: Execute Pipeline
    B-->>D: Status Report
    D-->>G: Build Status
```

### 4. Health Check Pattern
- Implementado em todos os serviços via Docker Compose
- Exemplo:
  ```yaml
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3000/"]
    interval: 30s
    timeout: 10s
    retries: 3
  ```

### 5. Dependency Injection via Environment
- Configuração centralizada no arquivo `.env`
- Injeção em tempo de execução:
  ```yaml
  environment:
    - DRONE_GITEA_SERVER=${DRONE_GITEA_SERVER}
    - DRONE_RPC_SECRET=${DRONE_RPC_SECRET}
  ```

## Considerações de Segurança

1. **Isolamento de Rede**:
   - Rede privada dedicada (devops-network)
   - Subnet específica (172.20.0.0/16)

2. **Gerenciamento de Secrets**:
   - Variáveis de ambiente sensíveis
   - Secrets gerados via OpenSSL
   - Armazenamento externo ao versionamento

3. **Controle de Acesso**:
   - SSH com chave pública
   - Permissões mínimas necessárias
   - Comunicação interna criptografada

4. **Proteção de Serviços**:
   - PostgreSQL acessível apenas internamente
   - Build Server com acesso restrito
   - Proxy reverso como único ponto de entrada público

Este diagrama e padrões seguem as melhores práticas de:
- Isolamento de componentes
- Separação de responsabilidades
- Configuração como código
- Segurança por padrão
- Observabilidade integrada