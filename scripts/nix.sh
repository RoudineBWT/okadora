#!/usr/bin/env bash

set -eoux pipefail

echo "Installing Nix for immutable systems..."

# FIX: kernel.sh breaks /root - recreate it if needed
echo "Checking /root status..."
ls -la / | grep "^d" | grep root || echo "/root issue detected"

if [ ! -d /root ] || [ ! -w /root ]; then
    echo "Fixing /root directory..."
    rm -rf /root 2>/dev/null || true
    mkdir -p /root
    chmod 0750 /root
    chown root:root /root
fi

# Verify /root works
if ! touch /root/.test 2>/dev/null; then
    echo "ERROR: Still cannot write to /root after fix"
    mount | grep root || true
    ls -la / | grep root || true
    exit 1
fi
rm -f /root/.test
echo "✓ /root is accessible"

# Now install Nix
dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm || true

# Verify installation
if ! rpm -q nix-multi-user; then
    echo "ERROR: Nix RPM installation failed"
    exit 1
fi

echo "Nix RPM installed successfully"

# Create necessary directories
mkdir -p /var/lib/nix
mkdir -p /var/cache/nix
mkdir -p /nix/var/nix/profiles/per-user/root

# Configure Nix
mkdir -p /etc/nix
cat > /etc/nix/nix.conf << 'EOF'
sandbox = false
filter-syscalls = false
experimental-features = nix-command flakes
build-users-group = nixbld
max-jobs = auto
EOF

# Setup channels - write directly to FILE
echo "https://nixos.org/channels/nixpkgs-unstable nixpkgs" > /root/.nix-channels

# Configure the default profile if nix binary exists
if [ -f /nix/var/nix/profiles/default/bin/nix-channel ]; then
    echo "Configuring nix-channel..."
    /nix/var/nix/profiles/default/bin/nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs || true
    /nix/var/nix/profiles/default/bin/nix-channel --update || true
fi

# Create systemd override for CachyOS kernel compatibility
mkdir -p /etc/systemd/system/nix-daemon.service.d
cat > /etc/systemd/system/nix-daemon.service.d/override.conf << 'EOF'
[Service]
LimitNOFILE=1048576
LimitNPROC=512
TasksMax=infinity
EOF

echo "Nix installation and configuration completed"
