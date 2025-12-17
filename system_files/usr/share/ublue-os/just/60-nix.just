# Install Nix Package Manager with SELinux support
install-nix:
    #!/usr/bin/bash
    set -euo pipefail
    
    echo "🔧 Installing Nix Package Manager..."
    echo ""
    
    # Check if Nix is already installed
    if [ -d "/nix" ] && [ -f "/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh" ]; then
        echo "✅ Nix is already installed!"
        echo "To load Nix in your shell, run:"
        echo "  source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
        exit 0
    fi
    
    echo "📦 Downloading Determinate Nix Installer..."
    echo "   (Compatible with SELinux and Fedora Atomic)"
    echo ""
    
    # Create /var/lib/nix directory if it doesn't exist
    if [ ! -d "/var/lib/nix" ]; then
        echo "📁 Creating /var/lib/nix..."
        sudo mkdir -p /var/lib/nix
        sudo chmod 0755 /var/lib/nix
    fi
    
    # Create /nix mount point if it doesn't exist
    if [ ! -d "/nix" ]; then
        echo "📁 Creating /nix..."
        sudo mkdir -p /nix
    fi
    
    # Create and enable nix.mount if needed
    if [ ! -f "/etc/systemd/system/nix.mount" ]; then
        echo "⚙️  Configuring systemd mount..."
        sudo tee /etc/systemd/system/nix.mount > /dev/null <<'EOF'
[Unit]
Description=Nix Package Manager
DefaultDependencies=no
After=local-fs.target
Before=sockets.target
ConditionPathExists=/var/lib/nix

[Mount]
What=/var/lib/nix
Where=/nix
Options=bind
Type=none

[Install]
WantedBy=multi-user.target
EOF
        sudo systemctl daemon-reload
        sudo systemctl enable --now nix.mount
    fi
    
    # Install Nix
    echo ""
    echo "🚀 Installing Nix (this may take a few minutes)..."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
        sh -s -- install ostree --no-confirm
    
    echo ""
    echo "✅ Nix has been successfully installed!"
    echo ""
    echo "📝 To use Nix, you need to:"
    echo "   1. Reload your shell or logout/login"
    echo "   2. Or run: source /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"
    echo ""
    echo "🎯 Useful commands:"
    echo "   - Search for a package:  nix search nixpkgs <name>"
    echo "   - Install a package:     nix profile install nixpkgs#<name>"
    echo "   - Run a package:         nix run nixpkgs#<name>"
    echo ""

# Uninstall Nix Package Manager
uninstall-nix:
    #!/usr/bin/bash
    set -euo pipefail
    
    echo "🗑️  Uninstalling Nix Package Manager..."
    echo ""
    
    if [ ! -d "/nix" ]; then
        echo "❌ Nix is not installed."
        exit 0
    fi
    
    echo "⚠️  This will remove:"
    echo "   - All installed Nix packages"
    echo "   - All Nix configurations"
    echo "   - The /nix directory"
    echo ""
    read -p "Are you sure? (yes/no): " confirm
    
    if [ "$confirm" != "yes" ]; then
        echo "❌ Uninstallation cancelled."
        exit 0
    fi
    
    # Disable and remove the mount
    if systemctl is-active --quiet nix.mount; then
        sudo systemctl stop nix.mount
    fi
    if systemctl is-enabled --quiet nix.mount; then
        sudo systemctl disable nix.mount
    fi
    
    # Run the Nix uninstaller
    if [ -f "/nix/nix-installer" ]; then
        sudo /nix/nix-installer uninstall --no-confirm
    fi
    
    # Clean up remaining files
    sudo rm -rf /nix /var/lib/nix
    sudo rm -f /etc/systemd/system/nix.mount
    sudo systemctl daemon-reload
    
    echo "✅ Nix has been uninstalled."