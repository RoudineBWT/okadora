#!/bin/bash
# Okadora User Setup Script - Optional user-specific apps

set -euo pipefail

log() {
    echo "[Okadora FirstBoot User] $1"
    logger -t okadora-firstboot "$1"
}

log "Starting user configuration for $USER"

if [ -z "${HOME:-}" ]; then
    log "ERROR: HOME is not defined"
    exit 1
fi

# Copy configuration files from /etc/skel
if [ -d "/etc/skel" ]; then
    log "Copying configurations from /etc/skel to $HOME"
    rsync -a --ignore-existing /etc/skel/ "$HOME/" 2>&1 | logger -t okadora-firstboot || true
else
    log "WARNING: /etc/skel does not exist"
fi

# Install Starship via Homebrew
if command -v brew >/dev/null 2>&1; then
    if ! command -v starship >/dev/null 2>&1; then
        log "Installing Starship via Homebrew"
        brew install starship 2>&1 | logger -t okadora-firstboot || true
    fi
fi

# Install OPTIONAL flatpaks (user-specific)
if command -v flatpak >/dev/null 2>&1; then
    log "Installing optional user flatpaks"
    
    # Check if flathub remote exists for user
    if ! flatpak remotes --user | grep -q flathub; then
        log "Adding flathub remote for user"
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi
    
    # Optional apps - user installation
    OPTIONAL_FLATPAKS=(
        "com.spotify.Client"
        "com.stremio.Stremio"
        "dev.vencord.Vesktop"
        "com.obsproject.Studio"
        "com.dec05eba.gpu_screen_recorder"
        "io.podman_desktop.PodmanDesktop"
        "org.nickvision.tubeconverter"
        "com.heroicgameslauncher.hgl"
        "org.prismlauncher.PrismLauncher"
    )
    
    for app in "${OPTIONAL_FLATPAKS[@]}"; do
        if ! flatpak list --user | grep -q "$app"; then
            log "Installing user flatpak: $app"
            flatpak install --user -y --noninteractive flathub "$app" 2>&1 | logger -t okadora-firstboot || true
        fi
    done
    
    # OBS DroidCam plugin (user)
    if flatpak list --user | grep -q "com.obsproject.Studio"; then
        log "Installing OBS DroidCam plugin"
        flatpak install --user -y --noninteractive flathub com.obsproject.Studio.Plugin.DroidCam 2>&1 | logger -t okadora-firstboot || true
    fi
    
    log "User flatpaks installation complete"
fi

# Spicetify (only if Spotify is installed - check both system and user)
if flatpak list | grep -q "com.spotify.Client"; then
    if ! command -v spicetify >/dev/null 2>&1; then
        log "Installing Spicetify"
        curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh 2>&1 | logger -t okadora-firstboot || true
        
        if ! grep -q "spicetify" "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.spicetify:$PATH"' >> "$HOME/.bashrc"
        fi
        
        sleep 2
        
        if [ -x "$HOME/.spicetify/spicetify" ]; then
            export PATH="$HOME/.spicetify:$PATH"
            spicetify config spotify_path "$HOME/.var/app/com.spotify.Client/config/spotify" 2>&1 | logger -t okadora-firstboot || true
            spicetify config prefs_path "$HOME/.var/app/com.spotify.Client/config/spotify/prefs" 2>&1 | logger -t okadora-firstboot || true
            spicetify backup apply 2>&1 | logger -t okadora-firstboot || true
            log "Spicetify installed and configured"
        fi
    fi
fi

log "User configuration completed successfully for $USER"
exit 0