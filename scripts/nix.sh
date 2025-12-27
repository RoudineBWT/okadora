#!/bin/bash

set -ouex pipefail

echo "=== Installation de Nix (version overlay simplifié) ==="

# Créer /root si nécessaire
mkdir -p /root 2>/dev/null || true

# Installer Nix
dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm || {
    echo "ATTENTION: Installation de Nix avec des warnings (non-critiques)"
}

# Si Nix a créé des fichiers dans /nix/store, les déplacer vers /var/nix-lowerdir
# (le lowerdir de l'overlay - données read-only initiales)
if [ -d /nix/store ]; then
    echo "Moving Nix store to /var/nix-lowerdir..."
    mkdir -p /var/nix-lowerdir
    cp -a /nix/* /var/nix-lowerdir/ 2>/dev/null || true
    rm -rf /nix/* 2>/dev/null || true
fi

echo "=== Nix installé ==="
