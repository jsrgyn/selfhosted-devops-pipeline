docker-compose down
docker-compose down -v
docker volume prune -f
docker volume ls
rm -rf data/*
#docker-compose up -d
docker-compose --env-file .env up -d
docker-compose --env-file .env up --build --force-recreate -d

#or

docker-compose down
docker-compose up -d



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

# Para e remove os containers do Drone
docker-compose rm --stop --force drone-server drone-runner

# Sobe eles novamente com a nova configuração
docker-compose --env-file .env up -d --no-deps drone-server drone-runner

# Para e remove o container antigo para garantir que ele pegue as novas variáveis
docker-compose rm --stop --force drone-server

# Sobe apenas o drone-server
docker-compose --env-file .env up -d --no-deps drone-server

docker-compose --env-file .env up -d --force-recreate --no-deps drone-server nginx

docker-compose restart nginx

docker-compose logs -f drone-runner

# A partir do container drone-runner-ssh
docker exec -it drone_runner_ssh ping drone_server

docker logs -f drone_runner_ssh

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


