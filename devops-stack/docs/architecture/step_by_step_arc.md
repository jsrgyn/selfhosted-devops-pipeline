# 🛠 Manual — Portabilidade ARM64 ↔ x86_64 e Pacotes Multi-Arquitetura no Docker

## 📌 Objetivo
Este guia ensina como:
- Migrar uma stack Docker de **ARM64** para **x86_64** (e vice-versa);
- Garantir que imagens e pacotes (ex.: SonarScanner) funcionem em **ambas as arquiteturas**;
- Aplicar boas práticas de desenvolvimento e manutenção no `Dockerfile` e `docker-compose.yml`.

---

## 1️⃣ Contexto da Migração

### Situação Atual (exemplo):
- **Host:** ARM64 (Apple M1/M2/M3 ou servidor ARM)
- **Imagens Docker:** compatíveis com `linux/arm64`
- **Build Server Node:** compilado com `--platform=linux/arm64`

### Ao migrar para x86_64:
- Imagens precisam ser compatíveis com `linux/amd64`
- Build de imagens customizadas não pode fixar ARM64
- Volumes persistentes podem ser reaproveitados **apenas se não contiverem binários compilados**

---

## 2️⃣ Ajustes no `docker-compose.yml`

### 2.1 Build de Imagens Customizadas
**Antes (fixo ARM64):**

```yaml
build:
  context: ./infra/docker/build-server
  dockerfile: Dockerfile
  args:
    NODE_VERSION: "${NODE_VERSION}"

FROM --platform=linux/arm64 ubuntu:jammy
```
Depois (x86_64 ou automático):

```yaml
FROM ubuntu:jammy
````

O Docker usará automaticamente a arquitetura do host.

💡 Para manter compatibilidade cruzada, use:

```bash
docker buildx build --platform linux/amd64,linux/arm64 .
```

⸻

2.2 Imagens Oficiais

Confirme se existe suporte amd64:

```bash
docker manifest inspect gitea/gitea:1.21 | grep architecture
```

Se não houver amd64, troque a tag por uma versão compatível.

⸻

2.3 Runner SSH

```bash
image: --platform=linux/amd64 drone/drone-runner-ssh:latest
```

Garante execução nativa no x86.

⸻

3️⃣ Ajustes no .env
	•	Variáveis em si não precisam mudar.
	•	Se houver pacotes binários específicos ARM, substitua por versão amd64 (ex.: Node.js, SonarScanner).

⸻

4️⃣ Ajustes no Dockerfile do Build Server

4.1 Plataforma

# Antes
```bash
FROM --platform=linux/arm64 ubuntu:jammy
```
# Depois
```bash
FROM ubuntu:jammy
```
# ou
```bash
FROM --platform=linux/amd64 ubuntu:jammy
```

4.2 Pacotes de Terceiros
	•	Node.js: instalador detecta arquitetura automaticamente.
	•	SonarScanner: use binários corretos para amd64/arm64.
	•	PM2/Yarn: instalação via npm é compatível com ambas.

⸻

5️⃣ Exemplo de Dockerfile Multi-Arquitetura (SonarScanner)

```yaml
# Stage 1 — Base
FROM debian:bullseye-slim AS base
ARG TARGETARCH
ENV SONARSCANNER_VERSION=5.0.1.3006

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl unzip ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Stage 2 — Instalação
FROM base AS install
WORKDIR /opt

RUN if [ "$TARGETARCH" = "amd64" ]; then \
      curl -fsSL -o sonarscanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONARSCANNER_VERSION}-linux.zip; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
      curl -fsSL -o sonarscanner.zip https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONARSCANNER_VERSION}-linux-arm64.zip; \
    else \
      echo "Arquitetura não suportada: $TARGETARCH" && exit 1; \
    fi \
 && unzip sonarscanner.zip \
 && mv sonar-scanner-* sonar-scanner \
 && rm sonarscanner.zip

# Stage 3 — Final
FROM debian:bullseye-slim
WORKDIR /opt
COPY --from=install /opt/sonar-scanner /opt/sonar-scanner
ENV PATH="/opt/sonar-scanner/bin:$PATH"
ENTRYPOINT ["sonar-scanner"]
```

⸻

6️⃣ Volumes e Dados Persistentes

Banco de Dados (Postgres)

⚠ Não reutilize volume binário ARM em x86.
	•	No ARM:

```bash
docker exec -t postgres_dbx pg_dumpall -U postgres > backup.sql
```

	•	No x86:

```bash
docker exec -i postgres_dbx psql -U postgres < backup.sql
```


Gitea / Drone / SonarQube
	•	Arquivos de configuração são compatíveis.
	•	Binários embutidos nos volumes podem precisar de rebuild.

⸻

7️⃣ Passo a Passo da Migração
	1.	Preparar ambiente x86

```bash
docker context use default
docker-compose down
docker system prune -af --volumes
```
	
	2.	Ajustar Dockerfile

	•	Trocar --platform=linux/arm64 por --platform=linux/amd64 ou remover.

	3.	Validar imagens

```bash
docker pull --platform=linux/amd64 gitea/gitea:1.21
docker pull --platform=linux/amd64 drone/drone:2.20
docker pull --platform=linux/amd64 sonarqube:10.5.1-community
docker pull --platform=linux/amd64 postgres:16
docker pull --platform=linux/amd64 nginx:alpine
```

	4.	Backup e restauração do Postgres (passo 6).
	5.	Subir stack

```bash
docker-compose up -d --build
````

	6.	Testar serviços

	•	gitea.local → login OK
	•	drone.local → builds OK
	•	sonar.local → análise OK
	•	build-server-node → SSH e builds OK

⸻

8️⃣ Boas Práticas de Multi-Arch

✅ Use multi-stage build para imagens leves
✅ Detecte arquitetura via TARGETARCH
✅ Baixe binário correto conforme arquitetura
✅ Limpe cache (rm -rf /var/lib/apt/lists/*)
✅ Parametrize versões via ENV
✅ Teste build multi-arch:

```bash
docker buildx create --name mybuilder --use
docker buildx build --platform linux/amd64,linux/arm64 -t minha-imagem:latest .
```

⸻

📚 Referências
	•	Documentação Docker Buildx
	•	SonarScanner CLI Downloads
	•	Docker Manifest Command

⸻