#!/bin/bash

set -ouex pipefail

echo "Installing Nix for immutable systems..."

# Ensure /root exists (required by RPM scriptlet)
mkdir -p /root

# Install Nix from community repository
# The RPM scriptlet error about /root is non-critical, we'll ignore it
dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm || {
  # If installation fails with exit code 1 but files are installed, continue
  if rpm -q nix-multi-user; then
    echo "Nix RPM installed despite scriptlet warnings"
  else
    echo "ERROR: Nix installation failed completely"
    exit 1
  fi
}

# For immutable systems: create necessary directories in writable locations
mkdir -p /var/lib/nix
mkdir -p /var/cache/nix

# If /nix exists from the RPM installation, we're good
# The system will bind-mount /var/lib/nix to /nix at runtime via systemd
if [ -d /nix ]; then
  echo "Nix installed successfully"
else
  echo "Creating /nix directory"
  mkdir -p /nix
fi

echo "Nix installation completed"
