#!/bin/bash

set -ouex pipefail

echo "=== Installation de Nix avec binaires complets ==="

# Créer /root si nécessaire
mkdir -p /root 2>/dev/null || true

# Créer la structure dans /var
mkdir -p /var/nix-lowerdir
mkdir -p /var/nix-upperdir
mkdir -p /var/nix-workdir

echo "=== Téléchargement des binaires Nix officiels ==="

# Télécharger l'archive officielle Nix avec tous les binaires
NIX_VERSION="2.24.10"
curl -L "https://releases.nixos.org/nix/nix-${NIX_VERSION}/nix-${NIX_VERSION}-x86_64-linux.tar.xz" \
    -o /tmp/nix.tar.xz

# Extraire dans /var/nix-lowerdir (le lowerdir de l'overlay)
echo "=== Extraction des binaires Nix ==="
tar xJf /tmp/nix.tar.xz -C /tmp

# Copier le contenu vers /var/nix-lowerdir
# L'archive contient un dossier nix-VERSION-x86_64-linux/store
NIX_EXTRACT_DIR=$(find /tmp -maxdepth 1 -name "nix-*-x86_64-linux" -type d | head -n 1)

if [ -d "$NIX_EXTRACT_DIR/store" ]; then
    echo "Copying Nix store to /var/nix-lowerdir..."
    cp -a "$NIX_EXTRACT_DIR/store" /var/nix-lowerdir/
fi

# Copier aussi les autres répertoires nécessaires
if [ -d "$NIX_EXTRACT_DIR/var" ]; then
    cp -a "$NIX_EXTRACT_DIR/var" /var/nix-lowerdir/
fi

# Nettoyer
rm -rf /tmp/nix.tar.xz "$NIX_EXTRACT_DIR"

echo "=== Installation du RPM Nix (pour les services et utilisateurs) ==="

# Installer quand même le RPM pour avoir les users, groups, et services systemd
dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm || {
    echo "ATTENTION: Installation du RPM Nix avec des warnings (non-critiques)"
}

# Nettoyer tout ce que le RPM a pu créer dans /nix
rm -rf /nix/* 2>/dev/null || true

# Vérifier que le store est bien là
if [ -d /var/nix-lowerdir/store ]; then
    echo "✓ Nix store extracted successfully"
    ls -lh /var/nix-lowerdir/store | head -5
else
    echo "✗ Warning: Nix store not found in /var/nix-lowerdir"
fi

echo "=== Nix installé avec binaires complets ==="
