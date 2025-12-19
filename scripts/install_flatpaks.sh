#!/bin/bash
# Install Flatpaks for Okadora

set -euo pipefail

echo "Adding Flathub remote if not exists..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

echo "Installing Flatpak applications..."

# List of Flatpaks to install
FLATPAKS=(
    # Browsers
    "org.mozilla.firefox"
    
    # Streaming & Recording
    "com.obsproject.Studio"
    "com.dec05eba.gpu_screen_recorder"
    
    # Media & Entertainment
    "io.bassi.Amberol"
    "org.gnome.Showtime"
    
    # Communication
    "org.telegram.desktop"
    "im.riot.Riot"
    
    # Creative Tools
    "org.gimp.GIMP"
    "com.github.wwmm.easyeffects"
    "org.nickvision.tubeconverter"
)
# Install each Flatpak
for app in "${FLATPAKS[@]}"; do
    echo "Installing $app..."
    flatpak install -y --noninteractive flathub "$app" || echo "Failed to install $app, continuing..."
done

# Install OBS DroidCam plugin
echo "Installing OBS DroidCam plugin..."
flatpak install -y --noninteractive flathub com.obsproject.Studio.Plugin.DroidCam || echo "Failed to install DroidCam plugin, continuing..."

echo "Flatpak installation complete!"