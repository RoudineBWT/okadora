#!/bin/bash
# Okadora First Boot Setup Script - System Service Version
# Applies configuration to all real users on first boot

set -euo pipefail

log() {
    echo "[Okadora FirstBoot System] $1"
    logger -t okadora-firstboot "$1"
}

log "Starting system-wide first boot configuration"

# Créer un script temporaire pour chaque utilisateur
TEMP_SCRIPT="/tmp/okadora-user-setup.sh"

cat > "$TEMP_SCRIPT" << 'SCRIPT_EOF'
#!/bin/bash
set -euo pipefail

log() {
    echo "[Okadora FirstBoot] $1"
    logger -t okadora-firstboot "$1"
}

log "Starting configuration for user $USER"

# Check that HOME is defined
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
        "org.mozilla.firefox"
        "org.telegram.desktop"
        "im.riot.Riot"
        "io.bassi.Amberol"
        "org.gnome.Showtime"
        "org.gimp.GIMP"
        "com.github.wwmm.easyeffects"
    )
    
    for app in "${ESSENTIAL_FLATPAKS[@]}"; do
        if ! flatpak list | grep -q "$app"; then
            log "Installing $app"
            flatpak install  -y --noninteractive flathub "$app" 2>&1 | logger -t okadora-firstboot || true
        fi
    done
    
    # Optional apps - nice to have
    log "Installing optional applications..."
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
            log "Installing $app"
            flatpak install --user -y --noninteractive flathub "$app" 2>&1 | logger -t okadora-firstboot || true
        fi
    done
    
    # Install OBS DroidCam plugin if OBS is installed
    if flatpak list --user | grep -q "com.obsproject.Studio"; then
        log "Installing OBS DroidCam plugin"
        flatpak install --user -y --noninteractive flathub com.obsproject.Studio.Plugin.DroidCam 2>&1 | logger -t okadora-firstboot || true
    fi
    
    log "Flatpak installation complete"
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

log "Configuration completed successfully for $USER"
SCRIPT_EOF

chmod +x "$TEMP_SCRIPT"

# Trouver tous les utilisateurs réels (UID >= 1000, avec un home dans /home ou /var/home)
while IFS=: read -r username _ uid _ _ homedir shell; do
    # Vérifier que c'est un utilisateur réel
    if [ "$uid" -ge 1000 ] && [ "$uid" -lt 65534 ] && [ -d "$homedir" ]; then
        log "Configuring for user: $username (UID: $uid, HOME: $homedir)"
        
        # Vérifier si déjà configuré pour cet utilisateur
        if [ -f "/var/lib/okadora/${username}-configured" ]; then
            log "User $username already configured, skipping"
            continue
        fi
        
        # Exécuter le script en tant qu'utilisateur
        su - "$username" "$TEMP_SCRIPT" 2>&1 | logger -t okadora-firstboot || log "Warning: Configuration for $username completed with errors"
        
        # Marquer comme configuré
        touch "/var/lib/okadora/${username}-configured"
        log "User $username configuration complete"
    fi
done < /etc/passwd

# Nettoyer
rm -f "$TEMP_SCRIPT"

log "System-wide first boot configuration completed"
log "This script will not run again"

exit 0