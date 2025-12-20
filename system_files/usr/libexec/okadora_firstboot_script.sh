#!/bin/bash
# Okadora First Boot Setup Script - System Service Version

set -euo pipefail

log() {
    echo "[Okadora FirstBoot System] $1"
    logger -t okadora-firstboot "$1"
}

log "Starting system-wide first boot configuration"

# Installer les flatpaks essentiels au niveau SYSTEM (une seule fois pour tous les utilisateurs)
if [ ! -f "/var/lib/okadora/system-flatpaks-installed" ]; then
    log "Installing essential system flatpaks"
    
    # Vérifier que flathub system existe
    if ! flatpak remotes --system | grep -q flathub; then
        log "Adding flathub remote for system"
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi
    
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
        if ! flatpak list --system | grep -q "$app"; then
            log "Installing system flatpak: $app"
            flatpak install --system -y --noninteractive flathub "$app" 2>&1 | logger -t okadora-firstboot || true
        fi
    done
    
    mkdir -p /var/lib/okadora
    touch /var/lib/okadora/system-flatpaks-installed
    log "System flatpaks installation complete"
fi

# Script utilisateur séparé
USER_SCRIPT="/usr/libexec/okadora_user_setup.sh"

# Trouver tous les utilisateurs réels
while IFS=: read -r username _ uid _ _ homedir shell; do
    if [ "$uid" -ge 1000 ] && [ -d "$homedir" ] && [[ "$homedir" == /home/* || "$homedir" == /var/home/* ]]; then
        log "Found user: $username (UID: $uid, HOME: $homedir)"
        
        if [ -f "/var/lib/okadora/${username}-configured" ]; then
            log "User $username already configured, skipping"
            continue
        fi
        
        log "Configuring user: $username"
        
        mkdir -p /var/lib/okadora
        su - "$username" "$USER_SCRIPT" 2>&1 | logger -t okadora-firstboot || log "Warning: Configuration for $username completed with errors"
        
        touch "/var/lib/okadora/${username}-configured"
        log "User $username configuration complete"
    fi
done < /etc/passwd

log "System-wide first boot configuration completed"
exit 0