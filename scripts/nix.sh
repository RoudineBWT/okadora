#!/usr/bin/env bash

set -eoux pipefail

echo "Installing Nix for immutable systems..."

# Install the Nix RPM (ignore post-install errors as they're expected in containers)
dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm || true

# Verify installation
if ! rpm -q nix-multi-user; then
    echo "ERROR: Nix RPM installation failed"
    exit 1
fi

echo "Nix RPM installed successfully"

# Create necessary directories (skip /root as it already exists)
mkdir -p /var/lib/nix
mkdir -p /var/cache/nix
mkdir -p /nix/var/nix/profiles/per-user/root

# Create .nix-channels in root's home (don't create /root itself)
mkdir -p /root/.nix-channels 2>/dev/null || true

# Configure Nix
mkdir -p /etc/nix
cat > /etc/nix/nix.conf << 'EOF'
sandbox = false
filter-syscalls = false
experimental-features = nix-command flakes
build-users-group = nixbld
max-jobs = auto
EOF

# Setup channels during build (write to file, not directory)
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
