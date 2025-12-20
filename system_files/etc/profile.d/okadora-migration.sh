#!/bin/bash
# Okadora migration prompt on first login after rebase

# Ne s'exécute que dans les sessions interactives bash/zsh
if [ -n "$PS1" ] && [ -n "$HOME" ]; then
    # Vérifier si c'est une image Okadora
    if [ -f /usr/libexec/okadora_firstboot_script.sh ]; then
        # Vérifier si l'utilisateur a déjà été migré ou a décliné
        if [ ! -f "$HOME/.config/okadora/migrated" ] && [ ! -f "$HOME/.config/okadora/migration-declined" ]; then
            # Vérifier si l'utilisateur a un .config existant MAIS pas de Niri
            # (donc c'est probablement un utilisateur qui existait avant le rebase)
            if [ -d "$HOME/.config" ] && [ ! -d "$HOME/.config/niri" ]; then
                # Attendre un peu pour que le terminal soit prêt
                sleep 1
                
                echo ""
                echo "╔════════════════════════════════════════════════════════════╗"
                echo "║          🎉 Welcome to Okadora! 🎉                        ║"
                echo "╚════════════════════════════════════════════════════════════╝"
                echo ""
                echo "It looks like you're using an existing user account."
                echo ""
                echo "Okadora includes:"
                echo "  🪟 Niri - A scrollable-tiling Wayland compositor"
                echo "  🎨 Noctalia - Modern shell interface"
                echo "  🐚 Fish - Friendly interactive shell"
                echo ""
                echo "Would you like to install these configurations now?"
                echo "(You can always run 'ujust migrate-to-okadora' later)"
                echo ""
                read -p "Install Okadora configs? [Y/n]: " -r
                echo
                
                if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                    echo "📦 Installing Okadora configurations..."
                    echo ""
                    
                    # Copier Niri
                    if [ -d "/etc/skel/.config/niri" ]; then
                        mkdir -p "$HOME/.config"
                        cp -r /etc/skel/.config/niri "$HOME/.config/"
                        echo "✅ Niri config installed"
                    fi
                    
                    # Copier Noctalia
                    if [ -d "/etc/skel/.config/noctalia" ]; then
                        mkdir -p "$HOME/.config"
                        cp -r /etc/skel/.config/noctalia "$HOME/.config/"
                        echo "✅ Noctalia config installed"
                    fi
                    
                    # Copier Fish
                    if [ -d "/etc/skel/.config/fish" ]; then
                        mkdir -p "$HOME/.config"
                        cp -r /etc/skel/.config/fish "$HOME/.config/"
                        echo "✅ Fish config installed"
                    fi
                    
                    # Marquer comme migré
                    mkdir -p "$HOME/.config/okadora"
                    touch "$HOME/.config/okadora/migrated"
                    
                    echo ""
                    echo "✨ Installation complete!"
                    echo ""
                    echo "Next steps:"
                    echo "  1. Log out (or restart)"
                    echo "  2. At the login screen, click the gear icon ⚙️"
                    echo "  3. Select 'Niri (Wayland)' as your session"
                    echo "  4. Log back in to experience Okadora!"
                    echo ""
                    echo "💡 Tip: Run 'ujust okadora-info' for more information"
                    echo ""
                else
                    echo ""
                    echo "⏭️  Skipped installation."
                    echo "   Run 'ujust migrate-to-okadora' anytime to install configs."
                    echo ""
                    
                    # Marquer comme "décliné" pour ne plus demander
                    mkdir -p "$HOME/.config/okadora"
                    touch "$HOME/.config/okadora/migration-declined"
                fi
            else
                # Si Niri existe déjà, marquer comme migré silencieusement
                if [ -d "$HOME/.config/niri" ]; then
                    mkdir -p "$HOME/.config/okadora"
                    touch "$HOME/.config/okadora/migrated" 2>/dev/null
                fi
            fi
        fi
    fi
fi
```

