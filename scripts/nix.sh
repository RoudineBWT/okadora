#!/bin/bash
# nix-determinate-install.sh

set -ouex pipefail

# Créer /var/nix
mkdir -p /var/nix

# Supprimer /nix s'il existe
rm -rf /nix

# Créer le symlink vers /var/nix
ln -sf /var/nix /nix

# Installer Nix avec Determinate Systems (meilleur pour ostree/bootc)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install ostree \
    --no-confirm \
    --init none

# Activer les services
systemctl enable nix-daemon.service
systemctl enable nix-daemon.socket

echo "Nix (Determinate Systems) installé avec support ostree"
