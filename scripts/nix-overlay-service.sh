#!/bin/bash

set -ouex pipefail

echo "=== Configuration Nix Overlay (compatible CachyOS) ==="

# Créer la structure de répertoires
mkdir -p /usr/share/nix-store
mkdir -p /var/lib/nix-store
mkdir -p /var/cache/nix-store
mkdir -p /nix

# Charger le module overlay au boot
echo overlay > /etc/modules-load.d/overlay.conf

# Créer le script de montage avec vérifications
cat << 'EOF' > /usr/bin/mount-nix-overlay.sh
#!/bin/bash
set -euo pipefail

echo "Waiting for /var to be ready..."

# Attendre que /var soit monté et writable (max 30 secondes)
timeout=30
while [ $timeout -gt 0 ]; do
    if [ -d /var/lib/nix-store ] && [ -w /var/lib/nix-store ] && \
       [ -d /var/cache/nix-store ] && [ -w /var/cache/nix-store ]; then
        echo "/var is ready"
        break
    fi
    sleep 1
    timeout=$((timeout - 1))
done

if [ $timeout -eq 0 ]; then
    echo "ERROR: /var not ready after 30 seconds"
    exit 1
fi

# Vérifier si /nix est déjà monté
if mountpoint -q /nix; then
    echo "/nix is already mounted"
    exit 0
fi

# Charger le module overlay si nécessaire
if ! lsmod | grep -q overlay; then
    modprobe overlay || {
        echo "ERROR: Failed to load overlay module"
        exit 1
    }
fi

# S'assurer que les répertoires existent
mkdir -p /usr/share/nix-store
mkdir -p /var/lib/nix-store
mkdir -p /var/cache/nix-store
mkdir -p /nix

# Monter l'overlay
echo "Mounting OverlayFS for /nix..."
mount -t overlay overlay \
    -o lowerdir=/usr/share/nix-store,upperdir=/var/lib/nix-store,workdir=/var/cache/nix-store \
    /nix || {
    echo "ERROR: Failed to mount overlay"
    exit 1
}

# Vérifier que le montage a réussi
if mountpoint -q /nix; then
    echo "✓ /nix successfully mounted"
    exit 0
else
    echo "✗ Failed to verify /nix mount"
    exit 1
fi
EOF

chmod +x /usr/bin/mount-nix-overlay.sh

# Créer le service systemd avec dépendances STRICTES pour CachyOS
cat << 'EOF' > /etc/systemd/system/nix-overlay.service
[Unit]
Description=Mount OverlayFS for /nix
Documentation=https://github.com/dnkmmr69420/nix-installer-scripts

# Dépendances STRICTES pour garantir que /var est prêt
RequiresMountsFor=/var/lib /var/cache
After=local-fs.target var.mount
Requires=local-fs.target

# DOIT être avant nix-daemon
Before=nix-daemon.service nix-daemon.socket

# Conditions de démarrage
ConditionPathExists=/usr/bin/mount-nix-overlay.sh
ConditionPathIsMountPoint=!/nix

[Service]
Type=oneshot
# Petit délai pour s'assurer que tout est stabilisé
ExecStartPre=/usr/bin/sleep 2
# Script de montage avec vérifications
ExecStart=/usr/bin/mount-nix-overlay.sh
# Vérification post-montage
ExecStartPost=/usr/bin/mountpoint -q /nix
ExecStop=/usr/bin/umount /nix
RemainAfterExit=yes

# Retry automatique si échec (important pour CachyOS)
Restart=on-failure
RestartSec=5s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

# Activer le service
systemctl enable nix-overlay.service

echo "=== Nix overlay configuré avec support CachyOS ==="
