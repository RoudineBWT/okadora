#!/bin/bash

# Attendre que colors.json soit écrit
sleep 1

COLORS_FILE="$HOME/.config/noctalia/colors.json"

if [ ! -f "$COLORS_FILE" ]; then
    echo "colors.json non trouvé"
    exit 1
fi

# Extraire la couleur primaire (structure: "mPrimary": "#1a151f")
PRIMARY=$(jq -r '.mPrimary' "$COLORS_FILE" 2>/dev/null | sed 's/#//')

if [ -z "$PRIMARY" ] || [ "$PRIMARY" = "null" ]; then
    echo "Impossible d'extraire la couleur primaire"
    exit 1
fi

# Lancer matugen avec vos templates personnalisés
echo "Génération des templates personnalisés avec #$PRIMARY"
matugen -c "$HOME/.config/noctalia/user-templates.toml" color hex "$PRIMARY"

echo "Templates générés avec succès !"