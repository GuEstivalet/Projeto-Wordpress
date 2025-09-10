#!/bin/bash
set -e

# ===== VARIÁVEIS =====
DB_HOST="wordpress-rds.caf68e8aor6r.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASSWORD="WpRds!2025#"
DB_NAME="wordpress"
EFS_DNS="fs-0295dff7c045688fa.efs.us-east-1.amazonaws.com"
MOUNT_POINT="/mnt/efs"
APP_DIR="/home/ubuntu/wordpress"
# ==============================

LOG_FILE="/var/log/user_data.log"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[1/8] Atualizando pacotes..."
sudo apt update -y
sudo apt upgrade -y

echo "[2/8] Instalando dependências..."
sudo apt install -y nfs-common git curl mysql-client docker.io docker-compose-plugin

# Instalar Docker Compose v2 via release (opcional, redundância)
DOCKER_COMPOSE_VERSION="2.29.7"
if [ ! -f /usr/local/bin/docker-compose ]; then
  echo "[3/8] Instalando Docker Compose v${DOCKER_COMPOSE_VERSION}..."
  sudo curl -SL "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
      -o /usr/local/bin/docker-compose
  sudo chmod +x /usr/local/bin/docker-compose
fi

echo "[4/8] Iniciando e habilitando Docker..."
sudo systemctl enable docker
sudo systemctl start docker

# Montar EFS
echo "[5/8] Montando EFS em $MOUNT_POINT..."
sudo mkdir -p $MOUNT_POINT
sudo mount -t nfs4 -o nfsvers=4.1 $EFS_DNS:/ $MOUNT_POINT
sudo chown -R ubuntu:ubuntu $MOUNT_POINT
sudo chmod -R 755 $MOUNT_POINT

# Criar diretório da aplicação
mkdir -p $APP_DIR
cd $APP_DIR

# Criar arquivo .env 
echo "[6/8] Criando arquivo .env..."
cat <<EOF > .env
DB_HOST=$DB_HOST
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_NAME=$DB_NAME
EOF
chmod 600 .env

# Garantir que o DB existe
echo "[7/8] Validando banco de dados no RDS..."
mysql --host=$DB_HOST --user=$DB_USER --password=$DB_PASSWORD -e "CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;"

# Criar docker-compose.yml com uso de variáveis do .env
echo "[8/8] Criando docker-compose.yml..."
cat <<'EOF' > docker-compose.yml
version: '3.9'
services:
  wordpress:
    image: wordpress:latest
    ports:
      - "80:80"
    env_file:
      - .env
    environment:
      WORDPRESS_DB_HOST: ${DB_HOST}:3306
      WORDPRESS_DB_USER: ${DB_USER}
      WORDPRESS_DB_PASSWORD: ${DB_PASSWORD}
      WORDPRESS_DB_NAME: ${DB_NAME}
    volumes:
      - /mnt/efs/wp-content:/var/www/html/wp-content
    restart: always
EOF

# Subir WordPress
docker compose up -d || docker-compose up -d

echo "✅ WordPress configurado e rodando! Veja logs em $LOG_FILE"

