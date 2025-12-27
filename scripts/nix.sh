#!/bin/bash

set -ouex pipefail

echo "=== Configuration de Nix avec systemd.mount ==="

# Créer le répertoire persistent dans /var
mkdir -p /var/nix

# Créer le point de montage /nix
mkdir -p /nix

echo "=== Installation de Nix ==="

# Installer Nix
dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm || {
    echo "ATTENTION: Installation de Nix avec des warnings (non-critiques)"
}

echo "=== Extraction du Nix store ==="

# Extraire le store Nix depuis l'archive fournie par le RPM
if [ -f /usr/share/nix/nix.tar.xz ]; then
    echo "Extracting Nix store to /var/nix..."
    # Extraire directement dans /var/nix
    tar -xJf /usr/share/nix/nix.tar.xz -C /var/nix --strip-components=1

    # Vérifier que l'extraction a réussi
    if [ -d /var/nix/store ]; then
        echo "✓ Nix store extracted successfully"
        ls -lah /var/nix/store | head -5
    else
        echo "✗ Failed to extract Nix store"
        exit 1
    fi
else
    echo "WARNING: /usr/share/nix/nix.tar.xz not found"
fi

# Créer les répertoires nécessaires
mkdir -p /var/nix/var/nix/daemon-socket
mkdir -p /var/nix/var/nix/profiles/per-user
mkdir -p /var/nix/var/nix/gcroots/per-user

# Fixer les permissions
chmod 0755 /var/nix/store || true
chmod 1777 /var/nix/var/nix/profiles/per-user || true
chmod 1777 /var/nix/var/nix/gcroots/per-user || true

echo "=== Nix installé avec succès ==="
