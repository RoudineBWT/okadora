#!/bin/bash
set -ouex pipefail

mkdir -p /root 2>/dev/null || true

dnf install -y https://nix-community.github.io/nix-installers/nix/x86_64/nix-multi-user-2.24.10.rpm

if [ -d /nix/store ]; then
  mkdir -p /usr/share/nix-store
  mv /nix/* /usr/share/nix-store/ || true
fi
