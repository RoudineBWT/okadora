# Okadora migration and setup recipes

# Migrate existing user to Okadora (copy Niri/Noctalia configs)
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
            echo "⚠️  Niri config already exists, skipping"
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
            echo "⚠️  Noctalia config already exists, skipping"
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

# Force reinstall all configs (overwrites existing)
reinstall-okadora-configs:
    #!/usr/bin/bash
    echo "⚠️  WARNING: This will OVERWRITE your existing Niri/Noctalia configs!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "📦 Reinstalling all Okadora configs..."
        
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
        
        mkdir -p "$HOME/.config/okadora"
        touch "$HOME/.config/okadora/migrated"
        
        echo "✨ All configs reinstalled!"
    else
        echo "❌ Cancelled."
    fi

# Show Okadora info
okadora-info:
    #!/usr/bin/bash
    echo "╔════════════════════════════════════════╗"
    echo "║          🌸 Okadora Info 🌸           ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "📦 Based on: Bazzite Gnome"
    echo "🪟 Window Manager: Niri (Wayland)"
    echo "🎨 Shell: Noctalia"
    echo "🐚 Terminal Shell: Fish"
    echo ""
    echo "Available commands:"
    echo "  ujust migrate-to-okadora        - Install Okadora configs"
    echo "  ujust reinstall-okadora-configs - Reinstall all configs"
    echo "  ujust okadora-info              - Show this info"
    echo ""
    echo "📚 Documentation: https://github.com/RoudineBWT/okadora"