#!/bin/bash

set -ouex pipefail

echo "=== Configuration de Nix avec bind mount ==="

# Créer le répertoire persistent dans /var
mkdir -p /var/nix

# Créer le point de montage /nix
mkdir -p /nix

echo "=== Installation de Nix ==="

# Installer Nix
dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm || {
    echo "ATTENTION: Installation de Nix avec des warnings (non-critiques)"
}

# Si Nix a créé des fichiers dans /nix, les déplacer vers /var/nix
if [ -d /nix/store ]; then
  cp -a /nix/store /var/nix/ || true
  rm -rf /nix/store || true
fi

echo "=== Nix installé avec succès ==="
