#!/bin/bash

set -ouex pipefail

echo "=== Configuration de Nix avec systemd.mount natif ==="

# S'assurer que les répertoires existent
mkdir -p /var/nix
mkdir -p /nix

# Créer le fichier systemd.mount
# IMPORTANT: Le nom du fichier DOIT correspondre au chemin de montage
# /nix = nix.mount
cat << 'EOF' > /etc/systemd/system/nix.mount
[Unit]
Description=Nix Store Mount Point
Documentation=https://nixos.org/manual/nix/stable/
# Attend que /var soit monté
RequiresMountsFor=/var
# Doit être monté avant que nix-daemon démarre
Before=nix-daemon.service nix-daemon.socket
# IMPORTANT: Ne pas mettre After=local-fs.target pour éviter le cycle
DefaultDependencies=no

[Mount]
What=/var/nix
Where=/nix
Type=none
Options=bind

[Install]
# CHANGEMENT CLÉ: multi-user.target au lieu de local-fs.target
WantedBy=multi-user.target
EOF

# Activer le mount
systemctl enable nix.mount

echo "=== systemd.mount configuré pour /nix ==="
