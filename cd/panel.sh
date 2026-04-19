#!/bin/bash

# Configuration
PHP_VERSION="8.3"
DB_NAME="panel"
DB_USER="pterodactyl"
DB_PASS=$(openssl rand -hex 12)

clear
echo "Starting Pterodactyl Panel Installation..."
read -p "Enter your domain (e.g., ://example.com): " DOMAIN

# 1. System Update & Dependencies
apt update && apt install -y curl apt-transport-https ca-certificates gnupg unzip git tar sudo lsb-release

# 2. Add Repositories (PHP & Redis)
OS=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
if [[ "$OS" == "ubuntu" ]]; then
    apt install -y software-properties-common
    add-apt-repository -y ppa:ondrej/php
else
    curl -fsSL https://sury.org | gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
    echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://sury.org $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/sury-php.list
fi

curl -fsSL https://redis.io | sudo gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://redis.io $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/redis.list

# 3. Install Software Stack
apt update
apt install -y php${PHP_VERSION} php${PHP_VERSION}-{cli,fpm,common,mysql,mbstring,bcmath,xml,zip,curl,gd,tokenizer,ctype,simplexml,dom} mariadb-server nginx redis-server

# 4. Install Composer
curl -sS https://getcomposer.org | php -- --install-dir=/usr/local/bin --filename=composer

# 5. Download Pterodactyl
mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com
tar -xzvf panel.tar.gz
chmod -R 755 storage/* bootstrap/cache/

# 6. Database Setup
mariadb -u root -e "CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
mariadb -u root -e "CREATE USER IF NOT EXISTS '${DB_USER}'@'127.0.0.1' IDENTIFIED BY '${DB_PASS}';"
mariadb -u root -e "GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'127.0.0.1' WITH GRANT OPTION;"
mariadb -u root -e "FLUSH PRIVILEGES;"

# 7. Environment Setup
cp .env.example .env
COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader

sed -i "s|APP_URL=http://localhost|APP_URL=https://${DOMAIN}|g" .env
sed -i "s|DB_PASSWORD=|DB_PASSWORD=${DB_PASS}|g" .env

php artisan key:generate --force
php artisan migrate --seed --force

# 8. Web Server & Permissions
chown -R www-data:www-data /var/www/pterodactyl/*
(crontab -l 2>/dev/null; echo "* * * * * php /var/www/pterodactyl/artisan schedule:run >> /dev/null 2>&1") | crontab -

# Nginx config... (ուղղված socket-ով)
tee /etc/nginx/sites-available/pterodactyl.conf > /dev/null << EOF
server {
    listen 80;
    server_name ${DOMAIN};
    root /var/www/pterodactyl/public;
    index index.php;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        fastcgi_pass unix:/run/php/php${PHP_VERSION}-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
ln -s /etc/nginx/sites-available/pterodactyl.conf /etc/nginx/sites-enabled/pterodactyl.conf
systemctl restart nginx

# 9. Admin Creation
php artisan p:user:make
echo "Panel installed at https://${DOMAIN}"
