# Migrate existing user to Okadora (install Niri/Noctalia configs)
migrate-to-okadora:
    #!/usr/bin/bash
    echo "🚀 Migrating your user to Okadora configuration..."
    
    # Copier les configs Niri
    if [ -d "/etc/skel/.config/niri" ]; then
        if [ ! -d "$HOME/.config/niri" ]; then
            echo "📦 Installing Niri configuration..."
            mkdir -p "$HOME/.config"
            cp -r /etc/skel/.config/niri "$HOME/.config/"
            echo "✅ Niri config installed"
        else
            echo "⚠️  Niri config already exists"
            read -p "Do you want to overwrite it? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp -rf /etc/skel/.config/niri "$HOME/.config/"
                echo "✅ Niri config overwritten"
            fi
        fi
    fi
    
    # Copier les configs Noctalia
    if [ -d "/etc/skel/.config/noctalia" ]; then
        if [ ! -d "$HOME/.config/noctalia" ]; then
            echo "📦 Installing Noctalia configuration..."
            mkdir -p "$HOME/.config"
            cp -r /etc/skel/.config/noctalia "$HOME/.config/"
            echo "✅ Noctalia config installed"
        else
            echo "⚠️  Noctalia config already exists"
            read -p "Do you want to overwrite it? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                cp -rf /etc/skel/.config/noctalia "$HOME/.config/"
                echo "✅ Noctalia config overwritten"
            fi
        fi
    fi
    
    # Copier autres configs importantes
    if [ -d "/etc/skel/.config/fish" ]; then
        if [ ! -d "$HOME/.config/fish" ]; then
            echo "📦 Installing Fish configuration..."
            mkdir -p "$HOME/.config"
            cp -r /etc/skel/.config/fish "$HOME/.config/"
            echo "✅ Fish config installed"
        fi
    fi
    
    # Marquer comme migré
    mkdir -p "$HOME/.config/okadora"
    touch "$HOME/.config/okadora/migrated"
    
    echo ""
    echo "✨ Migration complete! Please log out and back in for changes to take effect."
    echo "💡 Tip: Set Niri as your default session at the login screen."

# Force reinstall all Okadora configs (overwrites existing)
reinstall-okadora-configs:
    #!/usr/bin/bash
    echo "⚠️  WARNING: This will OVERWRITE your existing Niri/Noctalia configs!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Reinstalling all Okadora configs..."
        
        # Backup d'abord
        BACKUP_DIR="$HOME/.config/okadora-backup-$(date +%Y%m%d-%H%M%S)"
        mkdir -p "$BACKUP_DIR"
        
        if [ -d "$HOME/.config/niri" ]; then
            cp -r "$HOME/.config/niri" "$BACKUP_DIR/"
            echo "💾 Backup: $BACKUP_DIR/niri"
        fi
        
        if [ -d "$HOME/.config/noctalia" ]; then
            cp -r "$HOME/.config/noctalia" "$BACKUP_DIR/"
            echo "💾 Backup: $BACKUP_DIR/noctalia"
        fi
        
        # Réinstaller
        if [ -d "/etc/skel/.config/niri" ]; then
            mkdir -p "$HOME/.config"
            cp -rf /etc/skel/.config/niri "$HOME/.config/"
            echo "✅ Niri config reinstalled"
        fi
        
        if [ -d "/etc/skel/.config/noctalia" ]; then
            mkdir -p "$HOME/.config"
            cp -rf /etc/skel/.config/noctalia "$HOME/.config/"
            echo "✅ Noctalia config reinstalled"
        fi
        
        if [ -d "/etc/skel/.config/fish" ]; then
            mkdir -p "$HOME/.config"
            cp -rf /etc/skel/.config/fish "$HOME/.config/"
            echo "✅ Fish config reinstalled"
        fi
        
        echo ""
        echo "✨ All configs reinstalled!"
        echo "💾 Old configs backed up to: $BACKUP_DIR"
    else
        echo "❌ Cancelled."
    fi

# Show Okadora system information
okadora-info:
    #!/usr/bin/bash
    echo "╔════════════════════════════════════════╗"
    echo "║          🌸 Okadora Info 🌸           ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    
    # Image info
    if [ -f /usr/share/ublue-os/image-info.json ]; then
        IMAGE_NAME=$(jq -r '."image-name"' /usr/share/ublue-os/image-info.json 2>/dev/null || echo "okadora")
        IMAGE_TAG=$(jq -r '."image-tag"' /usr/share/ublue-os/image-info.json 2>/dev/null || echo "unknown")
        echo "📦 Image: $IMAGE_NAME:$IMAGE_TAG"
    fi
    
    echo "📦 Based on: Bazzite Gnome"
    echo "🪟 Window Manager: Niri (Wayland)"
    echo "🎨 Shell: Noctalia"
    echo "🐚 Terminal Shell: Fish"
    echo ""
    
    # Vérifier l'état de migration
    if [ -f "$HOME/.config/okadora/migrated" ]; then
        echo "✅ Okadora configs: Installed"
    else
        echo "⚠️  Okadora configs: Not installed"
    fi
    
    # Vérifier Niri
    if command -v niri &> /dev/null; then
        NIRI_VERSION=$(niri --version 2>/dev/null | head -n1 || echo "installed")
        echo "🪟 Niri: $NIRI_VERSION"
    fi
    
    echo ""
    echo "📋 Available commands:"
    echo "  ujust migrate-to-okadora        - Install Okadora configs"
    echo "  ujust reinstall-okadora-configs - Reinstall all configs (with backup)"
    echo "  ujust okadora-info              - Show this info"
    echo ""
    echo "📚 Documentation: https://github.com/RoudineBWT/okadora"

# Reset Okadora migration status (allows re-running migration)
reset-okadora-migration:
    #!/usr/bin/bash
    echo "🔄 Resetting Okadora migration status..."
    rm -f "$HOME/.config/okadora/migrated"
    rm -f "$HOME/.config/okadora/migration-declined"
    echo "✅ Migration status reset"
    echo "💡 Run 'ujust migrate-to-okadora' or restart your terminal to migrate again"

    # Backup current Okadora configs
backup-okadora-configs:
    #!/usr/bin/bash
    BACKUP_DIR="$HOME/.config/okadora-backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    if [ -d "$HOME/.config/niri" ]; then
        cp -r "$HOME/.config/niri" "$BACKUP_DIR/"
        echo "💾 Niri backed up to: $BACKUP_DIR"
    fi
    
    if [ -d "$HOME/.config/noctalia" ]; then
        cp -r "$HOME/.config/noctalia" "$BACKUP_DIR/"
        echo "💾 Noctalia backed up to: $BACKUP_DIR"
    fi
    
    echo "✅ Backup complete: $BACKUP_DIR"

# Show differences between current config and default
diff-okadora-configs:
    #!/usr/bin/bash
    echo "📊 Comparing your configs with Okadora defaults..."
    echo ""
    
    if [ -d "/etc/skel/.config/niri" ] && [ -d "$HOME/.config/niri" ]; then
        echo "🪟 Niri differences:"
        diff -r /etc/skel/.config/niri "$HOME/.config/niri" || true
        echo ""
    fi
    
    if [ -d "/etc/skel/.config/noctalia" ] && [ -d "$HOME/.config/noctalia" ]; then
        echo "🎨 Noctalia differences:"
        diff -r /etc/skel/.config/noctalia "$HOME/.config/noctalia" || true
    fi