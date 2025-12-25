#!/bin/bash
set -ouex pipefail

echo "=== Configuring Nix overlay service ==="

# Vérifier que les données Nix existent (installées par nix.sh)
if [ ! -d /usr/share/nix-store/store ]; then
  echo "✗ ERROR: /usr/share/nix-store/store not found!"
  echo "   Nix must be installed before configuring overlay"
  exit 1
fi

echo "✓ Nix store data found: $(ls /usr/share/nix-store/store 2>/dev/null | wc -l) items"

# Préparer les répertoires nécessaires
mkdir -p /usr/share/nix-store      # lowerdir (read-only, contient les données du build)
mkdir -p /var/lib/nix-store        # upperdir (read-write, changements)
mkdir -p /var/cache/nix-store      # workdir (requis par overlay)
mkdir -p /nix                       # point de montage

# Charger le module overlay au démarrage
echo overlay > /etc/modules-load.d/overlay.conf
echo "✓ Overlay module configured for auto-load"

# Créer le service systemd
cat << 'EOF' > /etc/systemd/system/nix-overlay.service
[Unit]
Description=Mount OverlayFS for /nix with Nix store data
Documentation=man:mount(8)
DefaultDependencies=no
Conflicts=umount.target
Before=local-fs.target umount.target nix-daemon.service
After=var.mount systemd-tmpfiles-setup.service
ConditionPathExists=/usr/share/nix-store/store
ConditionPathIsDirectory=/usr/share/nix-store/store

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/usr/bin/mkdir -p /var/lib/nix-store /var/cache/nix-store /nix
ExecStartPre=/usr/bin/sh -c 'echo "Preparing overlay mount: lowerdir=/usr/share/nix-store upperdir=/var/lib/nix-store workdir=/var/cache/nix-store"'
ExecStart=/usr/bin/mount -t overlay overlay -o lowerdir=/usr/share/nix-store,upperdir=/var/lib/nix-store,workdir=/var/cache/nix-store /nix
ExecStartPost=/usr/bin/sh -c 'if [ ! -d /nix/store ]; then echo "ERROR: /nix/store not found after overlay mount"; exit 1; fi'
ExecStartPost=/usr/bin/sh -c 'echo "✓ Overlay mounted successfully: $(ls /nix/store | wc -l) items in /nix/store"'
ExecStop=/usr/bin/umount /nix

[Install]
WantedBy=local-fs.target
RequiredBy=nix-daemon.service
EOF

# Activer le service
systemctl enable nix-overlay.service

echo "✓ Nix overlay service configured and enabled"

# CRITIQUE: Regénérer l'initramfs MAINTENANT que tout est configuré
# - Kernel CachyOS installé
# - Nix installé et données déplacées
# - Service overlay configuré
echo ""
echo "=== Regenerating initramfs with complete Nix overlay setup ==="
KERNEL_VERSION="$(find "/usr/lib/modules" -maxdepth 1 -type d ! -path "/usr/lib/modules" -exec basename '{}' ';' | sort | tail -n 1)"

if [ -z "$KERNEL_VERSION" ]; then
  echo "✗ ERROR: Could not find kernel version"
  exit 1
fi

echo "Kernel version: $KERNEL_VERSION"

# Vérifier que le module overlay existe pour ce kernel
if find "/usr/lib/modules/$KERNEL_VERSION" -name "overlay.ko*" | grep -q .; then
  echo "✓ Overlay module found for kernel $KERNEL_VERSION"
else
  echo "⚠ WARNING: Overlay module not found for kernel $KERNEL_VERSION"
fi

# Générer l'initramfs avec toute la configuration
export DRACUT_NO_XATTR=1
dracut --no-hostonly --kver "$KERNEL_VERSION" --reproducible --zstd -v --add ostree --force "/usr/lib/modules/$KERNEL_VERSION/initramfs.img"
chmod 0600 "/usr/lib/modules/${KERNEL_VERSION}/initramfs.img"

echo "✓ Initramfs regenerated successfully"
echo "✓ Nix overlay setup complete and ready for boot"
