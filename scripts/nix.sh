#!/bin/bash

set -ouex pipefail

echo "=== Installation de Nix (dxc-0 style) ==="

# Créer /root si nécessaire (évite l'erreur du scriptlet)
mkdir -p /root 2>/dev/null || true

# Installer Nix
dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm || {
    echo "ATTENTION: Installation de Nix avec des warnings (non-critiques)"
}

# Si Nix a créé des fichiers dans /nix/store, les déplacer vers usr/share/nix-store
# (pour qu'ils soient dans le lowerdir de l'overlay)
if [ -d /nix/store ]; then
    echo "Moving Nix store to /usr/share/nix-store..."
    mkdir -p /usr/share/nix-store
    cp -a /nix/* /usr/share/nix-store/ 2>/dev/null || true
    rm -rf /nix/* 2>/dev/null || true
fi

echo "=== Nix installé ==="
