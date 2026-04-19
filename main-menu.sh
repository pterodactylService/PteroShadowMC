#!/bin/bash
set -e

# COLORS
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
RESET='\033[0m'

# BANNER
banner() {
clear
echo -e "${RED}"
cat << "EOF"
███████╗██╗  ██╗ █████╗ ██████╗  ██████╗ 
██╔════╝██║  ██║██╔══██╗██╔══██╗██╔═══██╗
███████╗███████║███████║██║  ██║██║   ██║
╚════██║██╔══██║██╔══██║██║  ██║██║   ██║
███████║██║  ██║██║  ██║██████╔╝╚██████╔╝
╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝  ╚═════╝ 

     >>> ShadowCraft Pterodactyl Installer <<<
EOF
echo -e "${RESET}"
}

loading() {
echo -ne "${CYAN}Loading"
for i in {1..3}; do echo -ne "."; sleep 0.3; done
echo -e "${RESET}"
}

# =========================
# PANEL INSTALL
# =========================
install_panel() {

read -p "🌐 Domain (panel.example.com): " DOMAIN

apt update
apt install -y curl git unzip nginx mariadb-server redis-server software-properties-common

add-apt-repository -y ppa:ondrej/php
apt update
apt install -y php8.3 php8.3-{cli,fpm,mysql,mbstring,xml,zip,curl,gd,bcmath}

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

mkdir -p /var/www/pterodactyl
cd /var/www/pterodactyl

curl -Lo panel.tar.gz https://github.com/pterodactyl/panel/releases/latest/download/panel.tar.gz
tar -xzvf panel.tar.gz

cp .env.example .env
php artisan key:generate --force

DB_PASS=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 12)

mariadb -e "CREATE DATABASE panel;"
mariadb -e "CREATE USER 'ptero'@'127.0.0.1' IDENTIFIED BY '$DB_PASS';"
mariadb -e "GRANT ALL PRIVILEGES ON panel.* TO 'ptero'@'127.0.0.1';"

sed -i "s|APP_URL=.*|APP_URL=https://$DOMAIN|g" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|g" .env

COMPOSER_ALLOW_SUPERUSER=1 composer install --no-dev --optimize-autoloader
php artisan migrate --seed --force

chown -R www-data:www-data /var/www/pterodactyl

echo -e "${GREEN}Panel Installed! URL: https://$DOMAIN${RESET}"
}

# =========================
# WINGS INSTALL
# =========================
install_wings() {

echo "[*] Installing Docker..."
curl -sSL https://get.docker.com/ | bash
systemctl enable --now docker

mkdir -p /etc/pterodactyl

ARCH=$(uname -m)
if [ "$ARCH" == "x86_64" ]; then ARCH="amd64"; else ARCH="arm64"; fi

curl -L -o /usr/local/bin/wings "https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_$ARCH"
chmod +x /usr/local/bin/wings

echo -e "${GREEN}Wings Installed!${RESET}"
}

# =========================
# MENU LOOP
# =========================
while true; do
banner

echo -e "${YELLOW}Select:${RESET}"
echo -e "${GREEN}1) Install Panel${RESET}"
echo -e "${CYAN}2) Install Wings${RESET}"
echo -e "${BLUE}3) Full Install${RESET}"
echo -e "${RED}4) Exit${RESET}"
echo ""

read -p "Choice: " choice

case $choice in

  1)
    loading
    install_panel
    ;;

  2)
    loading
    install_wings
    ;;

  3)
    loading
    install_panel
    install_wings
    ;;

  4)
    exit
    ;;

  *)
    echo "Invalid"
    sleep 1
    ;;

esac

read -p "Press Enter..."
done
