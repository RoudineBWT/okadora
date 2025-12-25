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

# Créer tmpfiles.d pour garantir que les répertoires existent
cat << 'EOF' > /etc/tmpfiles.d/nix-overlay.conf
# Ensure directories for Nix overlay exist before nix-overlay.service starts
d /var/lib/nix-store 0755 root root -
d /var/cache/nix-store 0755 root root -
d /nix 0755 root root -
EOF
echo "✓ Tmpfiles.d configuration created"

# Configurer dracut pour inclure explicitement le module overlay
cat << 'EOF' > /etc/dracut.conf.d/overlay.conf
# Force inclusion of overlay module in initramfs
add_drivers+=" overlay "
EOF
echo "✓ Dracut configured to include overlay module"

# Configurer SELinux pour l'overlay Nix
# Ajouter le contexte approprié pour que SELinux autorise le montage overlay
if command -v semanage &> /dev/null && [ -f /etc/selinux/config ]; then
  echo "Configuring SELinux contexts for Nix overlay..."

  # Permettre au système de monter des overlayfs
  cat << 'SELINUX_EOF' > /usr/share/selinux/nix-overlay.te
module nix-overlay 1.0;

require {
    type mount_t;
    type fs_t;
    class filesystem mount;
}

# Allow mount to use overlay filesystem
allow mount_t fs_t:filesystem mount;
SELINUX_EOF

  # Compiler et installer le module SELinux (si possible)
  # Note: Cela peut échouer dans un conteneur, c'est normal
  if command -v checkmodule &> /dev/null && command -v semodule_package &> /dev/null; then
    checkmodule -M -m -o /tmp/nix-overlay.mod /usr/share/selinux/nix-overlay.te 2>/dev/null || true
    semodule_package -o /tmp/nix-overlay.pp -m /tmp/nix-overlay.mod 2>/dev/null || true
    # Note: semodule install will be done at runtime, not at build time
  fi

  echo "✓ SELinux policy prepared (will be loaded at runtime)"
else
  echo "✓ SELinux not found or disabled, skipping policy setup"
fi

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
# CRITIQUE: Charger le module overlay AVANT tout
ExecStartPre=/usr/sbin/modprobe overlay
ExecStartPre=/usr/bin/mkdir -p /var/lib/nix-store /var/cache/nix-store /nix
ExecStartPre=/usr/bin/sh -c 'echo "Preparing overlay mount: lowerdir=/usr/share/nix-store upperdir=/var/lib/nix-store workdir=/var/cache/nix-store"'
# Load SELinux policy if present and SELinux is enforcing
ExecStartPre=-/usr/bin/sh -c 'if [ -f /tmp/nix-overlay.pp ] && command -v semodule &>/dev/null && getenforce 2>/dev/null | grep -q Enforcing; then semodule -i /tmp/nix-overlay.pp; fi'
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

if [ -n "$KERNEL_VERSION" ]; then
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
else
  echo "✗ ERROR: Could not find kernel version"
  exit 1
fi
