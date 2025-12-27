#!/bin/bash

set -ouex pipefail

echo "=== Configuration Nix Overlay (version simplifiée) ==="

# Créer UNIQUEMENT dans /var (pas de /usr/share)
mkdir -p /var/nix-lowerdir
mkdir -p /var/nix-upperdir
mkdir -p /var/nix-workdir
mkdir -p /nix

# Charger le module overlay au boot
echo overlay > /etc/modules-load.d/overlay.conf

# Créer le script de montage simplifié
cat << 'EOF' > /usr/bin/mount-nix-overlay.sh
#!/bin/bash
set -euo pipefail

echo "Waiting for /var to be ready..."

# Attendre que /var soit accessible
timeout=30
while [ $timeout -gt 0 ]; do
    if [ -w /var/nix-lowerdir ] && [ -w /var/nix-upperdir ] && [ -w /var/nix-workdir ]; then
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

# Charger le module overlay
if ! lsmod | grep -q overlay; then
    modprobe overlay || {
        echo "ERROR: Failed to load overlay module"
        exit 1
    }
fi

# Créer les répertoires
mkdir -p /var/nix-lowerdir
mkdir -p /var/nix-upperdir
mkdir -p /var/nix-workdir
mkdir -p /nix

# NETTOYER le workdir (doit être vide)
echo "Cleaning workdir..."
rm -rf /var/nix-workdir/*
rm -rf /var/nix-workdir/.* 2>/dev/null || true

# Monter l'overlay - TOUT dans /var
echo "Mounting OverlayFS for /nix..."
mount -t overlay overlay \
    -o lowerdir=/var/nix-lowerdir,upperdir=/var/nix-upperdir,workdir=/var/nix-workdir \
    /nix || {
    echo "ERROR: Failed to mount overlay"
    exit 1
}

# Vérifier
if mountpoint -q /nix; then
    echo "✓ /nix successfully mounted"
    exit 0
else
    echo "✗ Failed to verify /nix mount"
    exit 1
fi
EOF

chmod +x /usr/bin/mount-nix-overlay.sh

# Service systemd
cat << 'EOF' > /etc/systemd/system/nix-overlay.service
[Unit]
Description=Mount OverlayFS for /nix
RequiresMountsFor=/var
After=local-fs.target var.mount
Before=nix-daemon.service nix-daemon.socket
ConditionPathExists=/usr/bin/mount-nix-overlay.sh
ConditionPathIsMountPoint=!/nix

[Service]
Type=oneshot
ExecStartPre=/usr/bin/sleep 2
ExecStart=/usr/bin/mount-nix-overlay.sh
ExecStartPost=/usr/bin/mountpoint -q /nix
ExecStop=/usr/bin/umount /nix
ExecStopPost=/usr/bin/rm -rf /var/nix-workdir/*
RemainAfterExit=yes
Restart=on-failure
RestartSec=5s
StartLimitBurst=3

[Install]
WantedBy=multi-user.target
EOF

systemctl enable nix-overlay.service

echo "=== Nix overlay configuré (tout dans /var) ==="
