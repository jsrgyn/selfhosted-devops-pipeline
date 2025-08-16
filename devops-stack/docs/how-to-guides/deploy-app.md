# Guia: Deploy de Nova Aplicação

## Contexto
Este guia mostra como adicionar uma nova aplicação ao ambiente DevOps.

## Passos

### 1. Criar Dockerfile
```bash
mkdir nova-aplicacao
cat <<EOF > nova-aplicacao/Dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["node", "server.js"]
EOF
```

### 2. Adicionar ao docker-compose.yml
```bash
cat <<EOF >> docker-compose.yml

  nova-aplicacao:
    build: ./nova-aplicacao
    image: nova-aplicacao:latest
    restart: unless-stopped
    networks:
      - devops-network
EOF
```

### 3. Configurar proxy reverso
```bash
cat <<EOF > config/nginx/conf.d/nova-aplicacao.conf
server {
    listen 80;
    server_name nova-app.local;

    location / {
        proxy_pass http://nova-aplicacao:3000;
    }
}
EOF
```

### 4. Implantar
```bash
docker-compose up -d --build nova-aplicacao
docker-compose restart nginx
```

## Validação
```bash
curl -I http://nova-app.local
```