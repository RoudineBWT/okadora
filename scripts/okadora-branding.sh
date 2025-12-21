#!/bin/bash
set -euo pipefail

echo "=== Forcing Okadora Branding ==="

HOME_URL="https://github.com/RoudineBWT/okadora"

# Force le branding même si déjà modifié par Bazzite
sed -i \
    -e 's|^NAME=.*|NAME="Okadora"|' \
    -e 's|^PRETTY_NAME=.*|PRETTY_NAME="Okadora"|' \
    -e 's|^VERSION_CODENAME=.*|VERSION_CODENAME="Posture"|' \
    -e 's|^VARIANT=.*|VARIANT="Niri Edition"|' \
    -e 's|^VARIANT_ID=.*|VARIANT_ID="okadora"|' \
    -e "s|^HOME_URL=.*|HOME_URL=\"${HOME_URL}\"|" \
    -e "s|^CPE_NAME=.*|CPE_NAME=\"cpe:/o:RoudineBWT:okadora\"|" \
    -e "s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL=\"${HOME_URL}\"|" \
    -e 's|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME="okadora"|' \
    /usr/lib/os-release

# Supprimer les lignes Red Hat
sed -i '/^REDHAT_BUGZILLA_PRODUCT/d' /usr/lib/os-release
sed -i '/^REDHAT_SUPPORT_PRODUCT/d' /usr/lib/os-release

echo "=== Okadora Branding Applied ==="