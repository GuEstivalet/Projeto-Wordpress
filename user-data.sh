#!/bin/bash
set -e

# ===== VARIÁVEIS =====
DB_HOST="your_value"
DB_USER="your_value"
DB_PASSWORD="your_value"
DB_NAME="wordpressdb"
EFS_DNS="your_value"
MOUNT_POINT="/mnt/efs"
APP_DIR="/home/ubuntu/wordpress"
LOG_FILE="/var/log/user_data.log"
# ======================

exec > >(tee -a "$LOG_FILE") 2>&1

log() {
  echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# 1. Atualiza pacotes
log "[1/7] Atualizando pacotes..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 2. Instala dependências
log "[2/7] Instalando dependências..."
sudo apt-get install -y git curl nfs-common mysql-client docker.io

# 3. Docker Compose
log "[3/7] Instalando Docker Compose..."
DOCKER_COMPOSE_VERSION="1.29.2"
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version

# 4. Habilita Docker
log "[4/7] Iniciando Docker..."
sudo systemctl enable docker
sudo systemctl start docker

# 5. Monta EFS
log "[5/7] Montando EFS em $MOUNT_POINT..."
sudo mkdir -p $MOUNT_POINT
sudo mount -t nfs4 -o nfsvers=4.1 $EFS_DNS:/ $MOUNT_POINT
sudo chmod -R 777 $MOUNT_POINT

# 6. Prepara diretório da aplicação
log "[6/7] Criando diretório da aplicação em $APP_DIR..."
sudo mkdir -p $APP_DIR
cd $APP_DIR

# Cria arquivo .env
cat <<EOF > .env
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
EOF
chmod 600 .env

# 7. Cria docker-compose.yml
log "[7/7] Criando docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: '3.9'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "80:80"
    env_file:
      - .env
    environment:
      WORDPRESS_DB_HOST: \${DB_HOST}:3306
      WORDPRESS_DB_USER: \${DB_USER}
      WORDPRESS_DB_PASSWORD: \${DB_PASSWORD}
      WORDPRESS_DB_NAME: \${DB_NAME}
    volumes:
      - $MOUNT_POINT/wp-content:/var/www/html/wp-content
    restart: always
EOF

# Sobe o ambiente
log "Subindo WordPress com Docker Compose..."
sudo docker-compose up -d

log "✅ Ambiente configurado e WordPress rodando! Veja logs em $LOG_FILE"
