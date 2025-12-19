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

# Install Starship via Homebrew if not already installed
if command -v brew >/dev/null 2>&1; then
    if ! command -v starship >/dev/null 2>&1; then
        log "Installing Starship via Homebrew"
        brew install starship 2>&1 | logger -t okadora-firstboot || true
    fi
fi

# Install Flatpak applications
if command -v flatpak >/dev/null 2>&1; then
    log "Installing Flatpak applications"
    
    # Essential apps - installed first
    log "Installing essential applications..."
    ESSENTIAL_FLATPAKS=(
        # Browser
        "org.mozilla.firefox"
        
        # Communication
        "org.telegram.desktop"
        "im.riot.Riot"
        
        # Media
        "io.bassi.Amberol"
        "org.gnome.Showtime"
        
        # Creative
        "org.gimp.GIMP"
        "com.github.wwmm.easyeffects"
    )
    
    for app in "${ESSENTIAL_FLATPAKS[@]}"; do
        if ! flatpak list --user | grep -q "$app"; then
            log "Installing $app"
            flatpak install --user -y --noninteractive flathub "$app" 2>&1 | logger -t okadora-firstboot || true
        fi
    done
    
    # Optional apps - nice to have
    log "Installing optional applications..."
    OPTIONAL_FLATPAKS=(
        # Media & Entertainment
        "com.spotify.Client"
        "com.stremio.Stremio"
        
        # Communication
        "dev.vencord.Vesktop"
        
        # Streaming & Recording
        "com.obsproject.Studio"
        "com.dec05eba.gpu_screen_recorder"
        
        # Development & Tools
        "io.podman_desktop.PodmanDesktop"
        
        # Creative Tools
        "org.nickvision.tubeconverter"
        
        # Gaming
        "com.heroicgameslauncher.hgl"
        "org.prismlauncher.PrismLauncher"
    )
    
    for app in "${OPTIONAL_FLATPAKS[@]}"; do
        if ! flatpak list --user | grep -q "$app"; then
            log "Installing $app"
            flatpak install -y --noninteractive flathub "$app" 2>&1 | logger -t okadora-firstboot || true
        fi
    done
    
    for app in "${USER_FLATPAKS[@]}"; do
        if ! flatpak list --user | grep -q "$app"; then
            log "Installing $app"
            flatpak install --user -y --noninteractive flathub "$app" 2>&1 | logger -t okadora-firstboot || true
        fi
    done
    
    log "User Flatpaks installation complete"
fi

# Install Spicetify for Spotify customization
if flatpak list --user | grep -q "com.spotify.Client"; then
    if ! command -v spicetify >/dev/null 2>&1; then
        log "Installing Spicetify"
        
        # Install Spicetify
        curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh 2>&1 | logger -t okadora-firstboot || true
        
        # Add Spicetify to PATH if not already there
        if ! grep -q "spicetify" "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.spicetify:$PATH"' >> "$HOME/.bashrc"
        fi
        
        # Wait for Spotify to be fully set up
        sleep 2
        
        # Initialize Spicetify with Spotify Flatpak
        if [ -x "$HOME/.spicetify/spicetify" ]; then
            export PATH="$HOME/.spicetify:$PATH"
            
            # Configure Spicetify for Flatpak
            spicetify config spotify_path "$HOME/.var/app/com.spotify.Client/config/spotify" 2>&1 | logger -t okadora-firstboot || true
            spicetify config prefs_path "$HOME/.var/app/com.spotify.Client/config/spotify/prefs" 2>&1 | logger -t okadora-firstboot || true
            
            # Backup and apply
            spicetify backup apply 2>&1 | logger -t okadora-firstboot || true
            
            log "Spicetify installed and configured"
        fi
    fi
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