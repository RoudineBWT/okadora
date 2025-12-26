#!/bin/bash

set -ouex pipefail

echo "=== Configuration de Nix dans /var ==="

# Créer la structure Nix directement dans /var
mkdir -p /var/nix/store
mkdir -p /var/nix/var/nix/daemon-socket
mkdir -p /var/nix/var/nix/profiles/per-user
mkdir -p /var/nix/var/nix/gcroots/per-user
mkdir -p /var/nix/var/nix/temproots
mkdir -p /var/nix/var/nix/userpool
mkdir -p /var/nix/var/nix/db

# Créer le fichier de configuration Nix pour utiliser /var/nix
mkdir -p /etc/nix
cat > /etc/nix/nix.conf << 'EOF'
# Configuration Nix pour utiliser /var/nix au lieu de /nix
store-dir = /var/nix/store
state-dir = /var/nix/var/nix
log-dir = /var/nix/var/log/nix
build-users-group = nixbld
experimental-features = nix-command flakes
EOF

# Créer le symlink /nix -> /var/nix pour la compatibilité
rm -rf /nix
ln -sf /var/nix /nix

echo "=== Installation de Nix ==="

# Installer Nix
dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm || {
    echo "ATTENTION: Installation de Nix avec des warnings (non-critiques)"
}

# Fixer les permissions
chmod 0755 /var/nix/store || true
chmod 1777 /var/nix/var/nix/profiles/per-user || true
chmod 1777 /var/nix/var/nix/gcroots/per-user || true

# Créer le fichier de configuration du daemon
mkdir -p /etc/systemd/system/nix-daemon.service.d
cat > /etc/systemd/system/nix-daemon.service.d/override.conf << 'EOF'
[Service]
Environment="NIX_REMOTE=daemon"
Environment="NIX_STATE_DIR=/var/nix/var/nix"
Environment="NIX_STORE_DIR=/var/nix/store"
EOF

# Configuration du socket
mkdir -p /etc/systemd/system/nix-daemon.socket.d
cat > /etc/systemd/system/nix-daemon.socket.d/override.conf << 'EOF'
[Socket]
ListenStream=/var/nix/var/nix/daemon-socket/socket
EOF

echo "=== Nix configuré pour utiliser /var/nix ==="
