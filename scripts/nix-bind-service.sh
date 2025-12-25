#!/bin/bash

set -ouex pipefail

echo "=== Configuration du service bind mount pour Nix ==="

# S'assurer que les répertoires existent
mkdir -p /var/nix
mkdir -p /nix

# Créer le service systemd pour bind mount
cat << 'EOF' > /etc/systemd/system/nix-bind.service
[Unit]
Description=Bind mount /var/nix to /nix
DefaultDependencies=no
After=local-fs.target var.mount
Requires=local-fs.target
Before=nix-daemon.service nix-daemon.socket
ConditionPathIsMountPoint=!/nix

[Service]
Type=oneshot
ExecStart=/usr/bin/mount --bind /var/nix /nix
ExecStop=/usr/bin/umount /nix
RemainAfterExit=yes

[Install]
WantedBy=local-fs.target
EOF

# Activer le service
systemctl enable nix-bind.service

echo "=== Service bind mount configuré ==="
