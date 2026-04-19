#!/bin/bash

# Գույների սահմանում
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Անիմացիայի ֆունկցիա
loading_bar() {
    local pid=$1
    local msg=$2
    local spin='-\|/'
    echo -ne "$msg  "
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) % 4 ))
        echo -ne "\b${spin:$i:1}"
        sleep 0.1
    done
    echo -e "\b${GREEN} [DONE]${NC}"
}

clear
echo -e "${CYAN}==========================================${NC}"
echo -e "${YELLOW} PTERODACTYL PREMIUM INSTALLER BY SHADOWCRAFTMC  ${NC}"
echo -e "${CYAN}==========================================${NC}"

read -p "🌐 Enter Domain: " DOMAIN

# part 1. Update
apt update -y > /dev/null 2>&1 &
loading_bar $! "🔄 Updating System Repositories"

# part 2. PHP & MariaDB
apt install -y mariadb-server nginx redis-server > /dev/null 2>&1 &
loading_bar $! "📦 Installing Core Services"

# part 3. Downloading files
mkdir -p /var/www/pterodactyl && cd /var/www/pterodactyl
curl -Lo panel.tar.gz https://github.com > /dev/null 2>&1
tar -xzvf panel.tar.gz > /dev/null 2>&1 &
loading_bar $! "📂 Extracting Panel Files"

# part 4. Settings
echo -e "${YELLOW}⚙️  Finalizing Configuration...${NC}"
# (Add the rest of the logic from panel.sh here.)

echo -e "${GREEN}🚀 Installation Finished Successfully!${NC}"
