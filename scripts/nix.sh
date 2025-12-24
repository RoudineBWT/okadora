#!/bin/bash

set -ouex pipefail

echo "Installing Nix for immutable systems..."

# Install Nix from community repository
# Note: The RPM scriptlet may show a non-critical warning about /root, which is expected
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
mkdir -p /nix

echo "Nix installation completed"
