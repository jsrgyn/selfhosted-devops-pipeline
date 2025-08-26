docker-compose down
docker-compose down -v
docker volume prune -f
docker volume ls
rm -rf data/*
#docker-compose up -d
docker-compose --env-file .env up -d
docker-compose --env-file .env up --build --force-recreate -d
docker-compose --env-file .env up --build --force-recreate -d

docker-compose down --volumes --remove-orphans
docker-compose --env-file .env up --build --force-recreate -d

#or

docker-compose down
docker-compose up -d

docker-compose logs -f

docker-compose restart nginx

docker-compose logs -f nginx

docker-compose up -d --build


docker exec -it nginx_proxy nginx -T  #Esse comando imprime toda a configuração do Nginx carregada no momento.


docker-compose down


docker-compose up --build --force-recreate -d
docker-compose logs -f sonarqube_x


docker exec -it nginx_proxy sh
docker exec -it nginx_proxy bash

docker exec -it drone_server sh

docker exec -it build_server_node sh

# Para e remove os containers do Drone
docker-compose rm --stop --force drone-server drone-runner

# Sobe eles novamente com a nova configuração
docker-compose --env-file .env up -d --no-deps drone-server drone-runner

# Para e remove o container antigo para garantir que ele pegue as novas variáveis
docker-compose rm --stop --force drone-server

# Sobe apenas o drone-server
docker-compose --env-file .env up -d --no-deps drone-server

docker-compose --env-file .env up -d --no-deps nginx

docker-compose --env-file .env up -d --force-recreate --no-deps drone-server nginx

docker-compose restart nginx

docker-compose logs -f drone-runner
docker-compose logs -f postgres_dbx

# A partir do container drone-runner-ssh
docker exec -it drone_runner_ssh ping drone_server

docker logs -f drone_runner_ssh
docker logs -f drone-server

docker exec -it drone_runner_ssh sh
# dentro do container:
apk update && apk add openssh
exit

ssh -i /id_rsa root@build-server-node



ssh -i ./ssh/id_rsa root@$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' build_server_node)


docker exec -it build_server_node sh
node -v && npm -v && git --version && java -version


 apk add --no-cache \
     openssh \
     bash \
     git \
     curl \
     rsync \
     nodejs \
     npm


docker exec -it build_server_node bash

cd /root/builds/<nome-do-repo>
npm ci

docker build -t devops-build-server:latest ./build-image/
docker build -t devops-build-server:latest ./build-image/

#2. Remover o container antigo (sem apagar volume/dados)
docker-compose stop build-server-node
docker-compose rm -f build-server-node

#3. Subir com a nova imagem já aplicada
docker-compose up -d --no-deps --force-recreate build-server-node

# Confirme se as variáveis estão definidas :
docker exec -it postgres_dbx env | grep -E 'POSTGRES|DB_PASSWORD'

# Verifique se os usuários foram criados :
docker exec -it postgres_dbx psql -U postgres -c "\du"

#Verifique se os bancos existem :
docker exec -it postgres_dbx psql -U postgres -c "\l"

#Verifique os logs do PostgreSQL :
docker-compose logs -f postgres_dbx

#Permissões: Garanta que o script seja executável:
chmod +x config/postgres/init-scripts/01-init-databases.sh

docker-compose logs -f drone_server

docker-compose build build-server-node

docker exec -it drone_runner_ssh nslookup build-server-node

docker network inspect devops-network

# Acesse o container do runner
docker exec -it drone_runner_ssh sh
# Dentro do container, tente pingar o build-server-node
ping build-server-node
# Se o ping falhar (mas o nslookup funcionar), pode ser um problema de rota ou firewall

docker logs drone_runner_ssh

# Reconstruir e Reiniciar os Containers
docker-compose build build-server-node
docker-compose down
docker-compose up -d

# Testar a Conexão SSH Manualmente
# Testar conexão do host
ssh -i secrets/ssh/id_rsa -p 2222 root@localhost

# Ou testar de dentro do runner
docker exec -it drone_runner_ssh sh
ssh -i /path/to/private_key -p 2222 root@build-server-node

docker ps -a | grep build-server-node

# Verificar status de saúde do container
docker inspect --format='{{.State.Status}}' build_server_node


# Parar o container
docker-compose stop build-server-node

# Reconstruir a imagem
docker-compose build build-server-node

# Remover o container antigo
docker-compose rm -f build-server-node

# Iniciar o novo container
docker-compose up -d build-server-node

# Verificar logs
docker logs build_server_node

# Do host
ssh -i secrets/ssh/id_rsa -p 2222 root@localhost

# Do container runner
docker exec -it drone_runner_ssh ssh -i /root/.ssh/id_rsa -p 22 root@build-server-node

docker exec -it drone_runner_ssh sh
ssh -i /root/.ssh/id_rsa root@build-server-node


ssh-keygen -t rsa -b 4096 -m PEM -f ./secrets/ssh/id_rsa
ssh-keygen -t rsa -b 4096 -f ./secrets/ssh/id_rsa -q -N ''
ssh-keygen -t rsa -b 4096 -f ./secrets/ssh/id_rsa -q -N ''