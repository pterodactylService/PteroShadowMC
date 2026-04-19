#!/bin/bash

clear
echo "🚀 Starting Pterodactyl Wings Installation..."

# 1. Install Docker
curl -sSL https://docker.com | CHANNEL=stable bash

# 2. Enable Docker on Boot
systemctl enable --now docker

# 3. Enable SWAP Support (Optional but Recommended)
# This allows you to limit RAM for game servers.
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="/GRUB_CMDLINE_LINUX_DEFAULT="swapaccount=1 /g' /etc/default/grub
update-grub

# 4. Install Wings
mkdir -p /etc/pterodactyl
curl -L -o /usr/local/bin/wings "https://github.com"
chmod +x /usr/local/bin/wings

# 5. Create Systemd Service
tee /etc/systemd/system/wings.service > /dev/null << EOF
[Unit]
Description=Pterodactyl Wings Daemon
After=docker.service
Requires=docker.service

[Service]
User=root
WorkingDirectory=/etc/pterodactyl
LimitNOFILE=4096
PIDFile=/var/run/wings/daemon.pid
ExecStart=/usr/local/bin/wings
Restart=always
RestartSec=2
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now wings

echo -e "\n✅ Wings installed! Now go to your Panel, create a Node, and paste the configuration in /etc/pterodactyl/config.yml"

