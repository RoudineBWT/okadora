#!/bin/bash
set -euo pipefail

echo "=== Applying Okadora branding (build-time) ==="

# custom name
HOME_URL="https://github.com/RoudineBWT/okadora"
echo "Okadora" | tee "/etc/hostname"

# Désactiver les overrides Bazzite potentiels
rm -f /etc/profile.d/bazzite-neofetch.sh 2>/dev/null || true
rm -f /etc/profile.d/bazzite-*.sh 2>/dev/null || true

# Chercher et désactiver les services de branding Bazzite
echo "=== Searching for Bazzite branding services ==="
find /usr/lib/systemd/system -name "*bazzite*branding*" -o -name "*ublue*branding*" 2>/dev/null | while read service; do
    echo "Found and removing: $service"
    rm -f "$service"
done

# Modifier os-release (sera aussi fait au boot par le service)
sed -i -f - /usr/lib/os-release <<EOF
s|^NAME=.*|NAME="Okadora"|
s|^PRETTY_NAME=.*|PRETTY_NAME="Okadora"|
s|^VERSION_CODENAME=.*|VERSION_CODENAME="Posture"|
s|^VARIANT=.*|VARIANT="Niri Edition"|
s|^VARIANT_ID=.*|VARIANT_ID="okadora"|
s|^HOME_URL=.*|HOME_URL="${HOME_URL}"|
s|^CPE_NAME=.*|CPE_NAME="cpe:/o:RoudineBWT:okadora"|
s|^DOCUMENTATION_URL=.*|DOCUMENTATION_URL="${HOME_URL}"|
s|^DEFAULT_HOSTNAME=.*|DEFAULT_HOSTNAME="okadora"|

/^REDHAT_BUGZILLA_PRODUCT=/d
/^REDHAT_BUGZILLA_PRODUCT_VERSION=/d
/^REDHAT_SUPPORT_PRODUCT=/d
/^REDHAT_SUPPORT_PRODUCT_VERSION=/d
EOF

echo "=== Configuring Okadora fastfetch ==="

# Créer le répertoire s'il n'existe pas
mkdir -p /etc/profile.d

# Remplacer l'alias Bazzite
cat > /etc/profile.d/okadora-neofetch.sh <<'EOF'
#!/bin/bash
# Okadora Fastfetch configuration
alias fastfetch='/usr/bin/fastfetch -c /usr/share/okadora/fastfetch.jsonc'
alias neofetch='/usr/bin/fastfetch -c /usr/share/okadora/fastfetch.jsonc'
EOF

chmod +x /etc/profile.d/okadora-neofetch.sh

echo "=== Okadora branding applied successfully ==="