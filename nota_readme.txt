# Ver logs em tempo real

docker-compose logs -f gitea
docker-compose logs -f sonarqube

# Reiniciar serviços específicos

docker-compose restart gitea
docker-compose restart sonarqube

# Atualizar imagens

docker-compose pull
docker-compose up -d

# Executar backup

./backup.sh

# Verificar status dos containers

docker-compose ps

# Verificar uso de recursos

docker stats

# Acessar shell dos containers

docker-compose exec gitea bash
docker-compose exec sonarqube bash
docker-compose exec db psql -U gitea

# Limpar dados (CUIDADO!)

docker-compose down -v
sudo rm -rf data/_ config/_

# Verificar conectividade entre serviços

docker-compose exec gitea ping sonarqube
docker-compose exec sonarqube ping db

# Analisar projeto com SonarScanner

docker run --rm \
 --network gitea-sonarqube-docker_gitea-network \
 -v "$(pwd):/usr/src" \
 sonarsource/sonar-scanner-cli

# Instalar certbot

sudo apt install certbot python3-certbot-nginx

# Obter certificados

sudo certbot --nginx -d git.seudominio.com -d sonar.seudominio.com

# Renovação automática

sudo crontab -e

# Adicionar linha:

0 12 \* \* \* /usr/bin/certbot renew --quiet

# Verificar logs

docker-compose logs sonarqube

# Verificar espaço em disco

df -h

# Limpar dados corrompidos

docker-compose down
docker volume rm gitea-sonarqube-docker_sonarqube_data
docker-compose up -d

# Testar conexão entre containers

docker-compose exec gitea ping sonarqube
docker-compose exec sonarqube ping db

# Verificar portas

docker-compose exec sonarqube netstat -tulpn

# Verificar logs do Gitea

docker-compose logs gitea | grep webhook

# Testar webhook manualmente

curl -X POST http://localhost:9000/api/webhooks/github \
 -H "Content-Type: application/json" \
 -d '{"repository":{"full_name":"user/repo"}}'

## Problemas Comuns:

# Permissões:
sudo chown -R 1000:1000 data config

# Porta em uso:
sudo netstat -tulpn | grep :3000

# Altere a porta no .env se necessário

# Logs de erro:
docker-compose logs gitea
docker-compose logs db

# Reset completo:
docker-compose down -v
sudo rm -rf data/\*
docker-compose up -d
