#!/bin/bash

set -ouex pipefail

echo "Setting up Nix mount service for immutable systems..."

# Create necessary directories
mkdir -p /var/lib/nix
mkdir -p /nix

# Create a simple systemd service that bind-mounts /var/lib/nix to /nix
cat << 'EOF' > /etc/systemd/system/nix-mount.service
[Unit]
Description=Mount /nix for Nix package manager
DefaultDependencies=no
After=local-fs.target
Before=nix-daemon.service
ConditionPathExists=/var/lib/nix

[Service]
Type=oneshot
ExecStartPre=/usr/bin/mkdir -p /nix
ExecStartPre=/usr/bin/mkdir -p /var/lib/nix
ExecStart=/usr/bin/mount --bind /var/lib/nix /nix
ExecStop=/usr/bin/umount /nix
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl enable nix-mount.service

echo "Nix mount service configured"
