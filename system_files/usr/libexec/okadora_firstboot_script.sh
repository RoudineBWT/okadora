#!/bin/bash
# Okadora First Boot Setup Script - System Service Version (Fedora Atomic)

set -euo pipefail

log() {
    echo "[Okadora FirstBoot System] $1"
    logger -t okadora-firstboot "$1"
}

log "Starting system-wide first boot configuration"

# Configuration du hostname
if [ ! -f "/var/lib/okadora/hostname-configured" ]; then
    log "Setting hostname to 'Okadora'"
    
    # Sur Fedora Atomic, hostnamectl fonctionne normalement
    hostnamectl set-hostname "Okadora" 2>&1 | logger -t okadora-firstboot || log "Warning: hostnamectl failed"
    
    mkdir -p /var/lib/okadora
    touch /var/lib/okadora/hostname-configured
    log "Hostname configured successfully"
fi

# Rebuild de l'initramfs pour Plymouth (spécifique Fedora Atomic)
if [ ! -f "/var/lib/okadora/initramfs-rebuilt" ]; then
    log "Rebuilding initramfs for Plymouth on Fedora Atomic"
    
    # Sur Fedora Atomic, on doit utiliser rpm-ostree avec l'argument dracut -I
    if command -v rpm-ostree &> /dev/null; then
        log "Using rpm-ostree to regenerate initramfs with dracut"
        
        # Activer l'initramfs avec les arguments dracut pour inclure Plymouth
        rpm-ostree initramfs --enable --arg="-I" --arg="/etc/plymouth" 2>&1 | logger -t okadora-firstboot || log "Warning: initramfs enable had errors"
        
        log "Note: A reboot is required for initramfs changes to take effect"
    else
        log "Warning: rpm-ostree not found, cannot rebuild initramfs on atomic system"
    fi
    
    mkdir -p /var/lib/okadora
    touch /var/lib/okadora/initramfs-rebuilt
    log "Initramfs rebuild complete"
fi

# Installer les flatpaks essentiels au niveau SYSTEM (une seule fois pour tous les utilisateurs)
if [ ! -f "/var/lib/okadora/system-flatpaks-installed" ]; then
    log "Installing essential system flatpaks"
    
    # Vérifier que flathub system existe
    if ! flatpak remotes --system | grep -q flathub; then
        log "Adding flathub remote for system"
        flatpak remote-add --if-not-exists --system flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi
    
    ESSENTIAL_FLATPAKS=(
        "org.mozilla.firefox"
        "com.github.tchx84.Flatseal"
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

# Configuration des thèmes et icônes pour les applications Flatpak
if [ ! -f "/var/lib/okadora/flatpak-themes-configured" ]; then
    log "Configuring Flatpak theme and icon access"
    
    flatpak override --system --filesystem=xdg-config/gtk-3.0:ro 2>&1 | logger -t okadora-firstboot || true
    flatpak override --system --filesystem=xdg-config/gtk-4.0:ro 2>&1 | logger -t okadora-firstboot || true
    flatpak override --system --filesystem=xdg-config/qt5ct:ro 2>&1 | logger -t okadora-firstboot || true
    flatpak override --system --filesystem=xdg-config/qt6ct:ro 2>&1 | logger -t okadora-firstboot || true
    flatpak override --system --filesystem=xdg-data/color-schemes:ro 2>&1 | logger -t okadora-firstboot || true
    flatpak override --system --filesystem=xdg-data/themes:ro 2>&1 | logger -t okadora-firstboot || true
    flatpak override --system --filesystem=xdg-data/icons:ro 2>&1 | logger -t okadora-firstboot || true
    flatpak override --system --filesystem=/usr/share/themes:ro 2>&1 | logger -t okadora-firstboot || true
    flatpak override --system --filesystem=/usr/share/icons:ro 2>&1 | logger -t okadora-firstboot || true
    flatpak override --system --env=QT_QPA_PLATFORMTHEME=kde 2>&1 | logger -t okadora-firstboot || true
    
    mkdir -p /var/lib/okadora
    touch /var/lib/okadora/flatpak-themes-configured
    log "Flatpak theme configuration complete"
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
