#!/bin/bash
# Okadora User Setup Script - SMART configuration on rebase

set -euo pipefail

log() {
    echo "[Okadora User Setup] $1"
    logger -t okadora-user-setup "$1"
}

log "Starting user configuration for $USER"

if [ -z "${HOME:-}" ]; then
    log "ERROR: HOME is not defined"
    exit 1
fi

# ============================================
# SYSTÈME DE VERSIONING
# ============================================
IMAGE_INFO="/usr/share/ublue-os/image-info.json"
if [[ -f "$IMAGE_INFO" ]]; then
    IMAGE_TAG=$(jq -r '."image-tag"' < "$IMAGE_INFO" 2>/dev/null || echo "unknown")
else
    IMAGE_TAG="unknown"
fi

# Flag basé sur la version de l'image
FLAG_FILE="${HOME}/.config/okadora-configured-${IMAGE_TAG}"

# Si déjà configuré pour cette version, skip
if [[ -f "$FLAG_FILE" ]]; then
    log "User $USER already configured for version ${IMAGE_TAG}"
    exit 0
fi

log "Configuring user $USER for Okadora ${IMAGE_TAG}"

# ============================================
# DÉTECTER SI C'EST UN NOUVEAU USER OU UN REBASE
# ============================================
# Si aucun flag okadora n'existe, c'est un nouveau user
IS_NEW_USER=true
if ls "${HOME}/.config/okadora-configured-"* 1> /dev/null 2>&1; then
    IS_NEW_USER=false
    log "Existing user detected (rebase scenario)"
else
    log "New user detected (fresh install scenario)"
fi

# ============================================
# BACKUP DES CONFIGS EXISTANTES (uniquement pour rebase)
# ============================================
if [[ "$IS_NEW_USER" == false ]]; then
    BACKUP_DIR="${HOME}/.config/okadora-backup-$(date +%Y%m%d-%H%M%S)"
    
    if [[ -f "${HOME}/.config/niri/config.kdl" ]] || [[ -d "${HOME}/.config/noctalia" ]]; then
        log "Backing up existing configs to $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        
        if [[ -d "${HOME}/.config/niri" ]]; then
            cp -r "${HOME}/.config/niri" "$BACKUP_DIR/" 2>/dev/null || true
        fi
        
        if [[ -d "${HOME}/.config/noctalia" ]]; then
            cp -r "${HOME}/.config/noctalia" "$BACKUP_DIR/" 2>/dev/null || true
        fi
        
        log "Backup created at: $BACKUP_DIR"
    fi
fi

# ============================================
# STRATÉGIE DE COPIE INTELLIGENTE
# ============================================

if [[ "$IS_NEW_USER" == true ]]; then
    # === NOUVEAU USER : Copier TOUT ===
    log "Applying full Okadora configuration for new user"
    
    # Tout copier depuis /etc/skel
    rsync -a /etc/skel/ "$HOME/" 2>&1 | logger -t okadora-user-setup || true
    
else
    # === REBASE : Copier SEULEMENT ce qui n'a PAS été modifié ===
    log "Smart merge for existing user (preserving personalizations)"
    
    # Pour Niri : copier seulement si le fichier n'existe PAS
    if [[ ! -f "${HOME}/.config/niri/config.kdl" ]]; then
        log "Niri config not found, applying default"
        mkdir -p "${HOME}/.config/niri"
        cp -r /etc/skel/.config/niri/* "${HOME}/.config/niri/" 2>/dev/null || true
    else
        log "Niri config exists, preserving user customizations"
        # Optionnel : copier les NOUVEAUX fichiers seulement
        if [[ -d "/etc/skel/.config/niri" ]]; then
            rsync -a --ignore-existing /etc/skel/.config/niri/ "${HOME}/.config/niri/" 2>/dev/null || true
        fi
    fi
    
    # Pour Noctalia : copier seulement si le dossier n'existe PAS
    if [[ ! -d "${HOME}/.config/noctalia" ]]; then
        log "Noctalia config not found, applying default"
        mkdir -p "${HOME}/.config/noctalia"
        cp -r /etc/skel/.config/noctalia/* "${HOME}/.config/noctalia/" 2>/dev/null || true
    else
        log "Noctalia config exists, preserving user customizations"
        # Copier seulement les nouveaux fichiers
        if [[ -d "/etc/skel/.config/noctalia" ]]; then
            rsync -a --ignore-existing /etc/skel/.config/noctalia/ "${HOME}/.config/noctalia/" 2>/dev/null || true
        fi
    fi
    
    # Autres configs : copier seulement ce qui n'existe pas
    log "Merging other configuration files (non-destructive)"
    rsync -a --ignore-existing /etc/skel/ "$HOME/" 2>&1 | logger -t okadora-user-setup || true
fi

# ============================================
# GNOME/GTK SETTINGS (seulement pour nouveaux users)
# ============================================
if [[ "$IS_NEW_USER" == true ]]; then
    log "Applying GTK/GNOME settings for new user"
    
    # Thème sombre
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' 2>/dev/null || true
    
    # Boutons de fenêtre
    gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close' 2>/dev/null || true
    
    # Police
    gsettings set org.gnome.desktop.interface font-name 'Cantarell 11' 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-antialiasing 'rgba' 2>/dev/null || true
else
    log "Preserving existing user's GTK/GNOME settings"
fi

# ============================================
# WALLPAPER (seulement si pas déjà configuré)
# ============================================
if [[ -d "/usr/share/backgrounds/okadora" ]]; then
    mkdir -p "${HOME}/.local/share/backgrounds"
    
    # Copier les wallpapers sans écraser
    rsync -a --ignore-existing /usr/share/backgrounds/okadora/ "${HOME}/.local/share/backgrounds/" 2>/dev/null || true
    
    # Appliquer seulement pour nouveaux users
    if [[ "$IS_NEW_USER" == true ]] && [[ -f "/usr/share/backgrounds/okadora/default.jpg" ]]; then
        log "Setting default wallpaper for new user"
        gsettings set org.gnome.desktop.background picture-uri "file://${HOME}/.local/share/backgrounds/default.jpg" 2>/dev/null || true
        gsettings set org.gnome.desktop.background picture-uri-dark "file://${HOME}/.local/share/backgrounds/default.jpg" 2>/dev/null || true
    fi
fi

# ============================================
# STARSHIP (via Homebrew)
# ============================================

if [[ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi


if command -v brew >/dev/null 2>&1; then
    if ! command -v starship >/dev/null 2>&1; then
        log "Installing Starship via Homebrew"
        brew install starship 2>&1 | logger -t okadora-user-setup || true
    fi
fi

# ============================================
# FLATPAKS UTILISATEUR (OPTIONNELS)
# ============================================
if command -v flatpak >/dev/null 2>&1; then
    log "Setting up optional user flatpaks"
    
    # Vérifier remote flathub user
    if ! flatpak remotes --user | grep -q flathub; then
        log "Adding flathub remote for user"
        flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
    fi
    
    # Apps optionnelles user (seulement pour nouveaux users ou si pas installées)
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
            flatpak install --user -y --noninteractive flathub "$app" 2>&1 | logger -t okadora-user-setup || true
        fi
    done
    
    # Plugin OBS DroidCam
    if flatpak list --user | grep -q "com.obsproject.Studio"; then
        if ! flatpak list --user | grep -q "com.obsproject.Studio.Plugin.DroidCam"; then
            log "Installing OBS DroidCam plugin"
            flatpak install --user -y --noninteractive flathub com.obsproject.Studio.Plugin.DroidCam 2>&1 | logger -t okadora-user-setup || true
        fi
    fi
    
    # Flatpak overrides (appliquer à chaque fois, c'est sans danger)
    log "Applying Flatpak overrides"
    flatpak override --user --env=GTK_THEME=Adwaita-dark 2>/dev/null || true
    flatpak override --user --socket=wayland 2>/dev/null || true
    flatpak override --user --filesystem=xdg-config/gtk-3.0:ro 2>/dev/null || true
    flatpak override --user --filesystem=xdg-config/gtk-4.0:ro 2>/dev/null || true
    flatpak override --user --filesystem=xdg-config/qt5ct:ro 2>/dev/null || true
    flatpak override --user --filesystem=xdg-config/qt6ct:ro 2>/dev/null || true
    flatpak override --user --filesystem=xdg-data/color-schemes:ro 2>/dev/null || true
    flatpak override --user --filesystem=~/.local/share/color-schemes:ro 2>/dev/null || true  
    log "Flatpaks setup complete"
fi

# ============================================
# SPICETIFY (pour Spotify)
# ============================================
if flatpak list | grep -q "com.spotify.Client"; then
    if ! command -v spicetify >/dev/null 2>&1; then
        log "Installing Spicetify"
        curl -fsSL https://raw.githubusercontent.com/spicetify/cli/main/install.sh | sh 2>&1 | logger -t okadora-user-setup || true
        
        if ! grep -q "spicetify" "$HOME/.bashrc" 2>/dev/null; then
            echo 'export PATH="$HOME/.spicetify:$PATH"' >> "$HOME/.bashrc"
        fi
        
        sleep 2
        
        if [ -x "$HOME/.spicetify/spicetify" ]; then
            export PATH="$HOME/.spicetify:$PATH"
            spicetify config spotify_path "$HOME/.var/app/com.spotify.Client/config/spotify" 2>&1 | logger -t okadora-user-setup || true
            spicetify config prefs_path "$HOME/.var/app/com.spotify.Client/config/spotify/prefs" 2>&1 | logger -t okadora-user-setup || true
            spicetify backup apply 2>&1 | logger -t okadora-user-setup || true
            log "Spicetify installed and configured"
        fi
    fi
fi

# ============================================
# ACTIVER NIRI SERVICE (si présent et pas déjà activé)
# ============================================
if [[ -f "${HOME}/.config/systemd/user/niri.service" ]]; then
    if ! systemctl --user is-enabled niri.service &>/dev/null; then
        log "Enabling Niri service"
        systemctl --user daemon-reload 2>/dev/null || true
        systemctl --user enable niri.service 2>/dev/null || true
    fi
fi

# ============================================
# MARQUER COMME CONFIGURÉ
# ============================================
mkdir -p "${HOME}/.config"
touch "$FLAG_FILE"

if [[ "$IS_NEW_USER" == true ]]; then
    log "New user configuration completed successfully (version ${IMAGE_TAG})"
else
    log "Rebase configuration completed successfully (version ${IMAGE_TAG})"
    log "Your personalizations have been preserved. Backup available at: $BACKUP_DIR"
fi

# Notification
if command -v notify-send &> /dev/null; then
    if [[ "$IS_NEW_USER" == true ]]; then
        notify-send -a "Okadora" -i "preferences-desktop-theme" \
            "Welcome on Okadora" \
            "Your environment has been successfully configured." 2>/dev/null || true
    else
        notify-send -a "Okadora" -i "preferences-desktop-theme" \
            "Okadora updated" \
            "Your customizations have been preserved.\nBackup: $BACKUP_DIR" 2>/dev/null || true
    fi
fi

exit 0