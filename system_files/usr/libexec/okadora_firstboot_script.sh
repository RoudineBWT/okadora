#!/bin/bash
# Okadora First Boot Setup Script
# Applies user configuration on first boot

set -euo pipefail

# Logger for systemd
log() {
    echo "[Okadora FirstBoot] $1"
}

log "Starting configuration for user $USER"

# Check that HOME is defined
if [ -z "${HOME:-}" ]; then
    log "ERROR: HOME is not defined"
    exit 1
fi

# Copy configuration files from /etc/skel
# --ignore-existing = don't overwrite existing files (additional safety)
# -a = archive mode (preserves permissions, timestamps, etc.)
if [ -d "/etc/skel" ]; then
    log "Copying configurations from /etc/skel to $HOME"
    rsync -a --ignore-existing /etc/skel/ "$HOME/" 2>&1 | logger -t okadora-firstboot || true
else
    log "WARNING: /etc/skel does not exist"
fi

# Okadora-specific configurations (optional)
# Uncomment and add your custom configs here:

# Example: Create specific directories
# mkdir -p "$HOME/.config/okadora"
# mkdir -p "$HOME/Documents" "$HOME/Downloads" "$HOME/Pictures"

# Example: Apply dconf settings (for GNOME)
# dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
# Set Niri as default session
if command -v dconf >/dev/null 2>&1; then
    dconf write /org/gnome/desktop/session/session-name "'niri'"
fi

# Example: Default Git configuration
# if ! git config --global user.name >/dev/null 2>&1; then
#     git config --global init.defaultBranch main
# fi

log "Configuration completed successfully for $USER"
log "This script will not run again for this user"

exit 0