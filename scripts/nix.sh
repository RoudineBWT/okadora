#!/bin/bash

set -ouex pipefail

echo "Installing Determinate Nix..."

# Download Determinate Nix installer
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  -o /tmp/install-determinate-nix.sh

chmod +x /tmp/install-determinate-nix.sh

# Install Determinate Nix with appropriate flags for container builds
# --no-confirm: Skip interactive prompts
# --init none: Don't set up init system integration (we'll do it manually)
/tmp/install-determinate-nix.sh install --no-confirm --init none || {
  echo "Determinate Nix installation failed, trying fallback method..."

  # Fallback: Install from nixos.org community installer
  dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm

  # Move nix store if needed for traditional installer
  if [ -d /nix/store ]; then
    mkdir -p /var/lib/nix
    mv /nix/* /var/lib/nix/ || true
  fi
}

# Clean up
rm -f /tmp/install-determinate-nix.sh

echo "Nix installation completed"
