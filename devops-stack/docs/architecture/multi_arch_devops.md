# Manual — Projeto DevOps Multi-Arquitetura

## 1. Objetivo
Permitir que o projeto identifique automaticamente a arquitetura do ambiente de execução (`arm64`, `amd64`/`x86_64`) e ajuste:
- Dependências (pacotes compatíveis com cada arquitetura)
- Imagens Docker
- Binários externos (como SonarScanner, QEMU, etc.)
- Etapas de build no CI/CD

---

## 2. Estratégias de Detecção de Arquitetura

### No Dockerfile
Usar **ARG** e variáveis automáticas do Docker:

```dockerfile
ARG TARGETARCH
ARG TARGETOS
ENV TARGETARCH=${TARGETARCH} \
    TARGETOS=${TARGETOS}

RUN echo "Arquitetura detectada: ${TARGETARCH} - OS: ${TARGETOS}"
```

Valores comuns de TARGETARCH: amd64, arm64, arm, 386.

⸻

No Shell (Local ou Pipeline)

```shell
ARCH=$(uname -m)
case "$ARCH" in
    x86_64)   echo "Arquitetura: amd64" ;;
    aarch64)  echo "Arquitetura: arm64" ;;
    armv7l)   echo "Arquitetura: arm" ;;
    *)        echo "Arquitetura desconhecida: $ARCH" ;;
esac
```

Exemplo no Drone CI:

```bash
steps:
  - name: detect-arch
    image: alpine
    commands:
      - echo "Rodando em arquitetura: $(uname -m)"
```

⸻

## 3. Ajustando Pacotes Dependendo da Arquitetura

Exemplo de instalação do SonarScanner:


```bash
RUN case "${TARGETARCH}" in \
    amd64)  curl -sSL -o sonarscanner.zip https://binaries.sonarsource.com/.../sonar-scanner-cli-linux-x86.zip ;; \
    arm64)  curl -sSL -o sonarscanner.zip https://binaries.sonarsource.com/.../sonar-scanner-cli-linux-arm64.zip ;; \
    *) echo "Arquitetura não suportada" && exit 1 ;; \
    esac \
 && unzip sonarscanner.zip -d /opt/sonarscanner \
 && rm sonarscanner.zip
```

⸻

## 4. Multi-Stage Builds com Imagens Diferentes

```dockerfile
FROM --platform=$BUILDPLATFORM node:20-alpine AS build
WORKDIR /app
COPY . .
RUN npm ci && npm run build

FROM --platform=$TARGETPLATFORM alpine:3.19
COPY --from=build /app/dist /app
CMD ["node", "/app/index.js"]
```

💡 O build roda em uma plataforma, mas o runtime pode ser outra.

⸻

## 5. Ajustando no Docker Compose

```bash
services:
  app:
    build:
      context: .
      args:
        TARGETARCH: ${TARGETARCH:-amd64}
    platform: ${PLATFORM:-linux/amd64}
```

No terminal:

```bash
TARGETARCH=$(uname -m) docker compose up --build
```

⸻

## 6. CI/CD Adaptativo

Exemplo no Drone CI:

```bash
steps:
  - name: build
    image: docker
    settings:
      dockerfile: Dockerfile
      build_args:
        - TARGETARCH=${DRONE_STAGE_ARCH}
```

O DRONE_STAGE_ARCH retorna amd64 ou arm64 automaticamente.

⸻

## 7. Boas Práticas
	•	Sempre usar --platform no docker build para garantir previsibilidade.
	•	Manter repositório de binários compatíveis com todas as arquiteturas necessárias.
	•	Validar arquitetura antes de instalar dependências críticas.
	•	Criar cache separado por arquitetura.
	•	Testar em ambiente local e CI/CD para ambas arquiteturas.
	•	Se usar QEMU para builds cruzados, configure:

```bash
docker run --privileged tonistiigi/binfmt
```

⸻

## 8. Dockerfile Multi-Arquitetura Completo

# syntax=docker/dockerfile:1.5

```dockerfile
FROM alpine:3.20 AS base

ARG TARGETARCH
ARG TARGETPLATFORM
ARG TARGETOS
ENV TARGETARCH=${TARGETARCH} \
    TARGETPLATFORM=${TARGETPLATFORM} \
    TARGETOS=${TARGETOS}
```

# Mostrar infos

```bash
RUN echo "Compilando para ${TARGETOS}/${TARGETARCH}"
```

# Pacotes por arquitetura
```bash
RUN case "${TARGETARCH}" in \
      "amd64")  echo "Instalando pacotes para x86_64..." && apk add --no-cache openjdk17 nodejs npm ;; \
      "arm64")  echo "Instalando pacotes para ARM64..." && apk add --no-cache openjdk17 nodejs npm ;; \
      *) echo "Arquitetura ${TARGETARCH} não suportada!" && exit 1 ;; \
    esac
```

# SonarScanner compatível

```bash
ENV SONAR_VERSION=5.0.1.3006
RUN case "$TARGETARCH" in \
      amd64) ARCH_DL="linux-x64";; \
      arm64) ARCH_DL="linux-aarch64";; \
      *) echo "Arquitetura não suportada: $TARGETARCH" && exit 1;; \
    esac && \
    wget -q https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-$SONAR_VERSION-$ARCH_DL.zip && \
    unzip sonar-scanner-cli-*.zip -d /opt && \
    rm sonar-scanner-cli-*.zip

ENV PATH="/opt/sonar-scanner-$SONAR_VERSION-${ARCH_DL}/bin:${PATH}"

WORKDIR /app
COPY . .
CMD ["sh"]
```

⸻

## 9. Script para Build Multi-Arquitetura

```bash
#!/bin/bash
IMAGE_NAME="meu-projeto"
VERSION="1.0.0"

docker buildx create --use --name multiarch-builder || docker buildx use multiarch-builder

docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t $IMAGE_NAME:$VERSION \
  -t $IMAGE_NAME:latest \
  --push .
```