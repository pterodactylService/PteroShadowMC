#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

loading() {
    local pid=$1
    local msg=$2
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 $pid 2>/dev/null; do
        for i in {0..9}; do
            echo -ne "\r${CYAN}${spin:$i:1}${NC} $msg..."
            sleep 0.1
        done
    done
    echo -e "\r${GREEN}✔${NC} $msg [DONE]"
}

clear
echo -e "${CYAN}==========================================${NC}"
echo -e "${YELLOW}       PTERODACTYL WINGS INSTALLER        ${NC}"
echo -e "${CYAN}==========================================${NC}"

# Step 1: Dependencies
apt update > /dev/null 2>&1 &
loading $! "Updating System"

# Step 2: Docker
if ! command -v docker &> /dev/null; then
    curl -sSL https://docker.com | CHANNEL=stable bash > /dev/null 2>&1 &
    loading $! "Installing Docker Engine"
else
    echo -e "${GREEN}✔${NC} Docker is already installed."
fi

# Step 3: Wings Binary
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com" > /dev/null 2>&1 &
loading $! "Downloading Wings Binary"
chmod +x /usr/local/bin/wings

# Step 4: Service Setup
tee /etc/systemd/system/wings.service > /dev/null << EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
ExecStart=/usr/local/bin/wings
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload > /dev/null 2>&1
systemctl enable wings > /dev/null 2>&1 &
loading $! "Finalizing Wings Service"

echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN} ✅ Wings Installation Complete!${NC}"
echo -e " 🔧 Config Path: ${CYAN}/etc/pterodactyl/config.yml${NC}"
echo -e " 🚀 Start Wings: ${CYAN}systemctl start wings${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

