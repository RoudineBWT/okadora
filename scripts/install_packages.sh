#!/bin/bash

set -ouex pipefail
repos=(
    solopasha/hyprland
    errornointernet/quickshell
    che/nerd-fonts
    isaksamsten/niriswitcher
)

for repo in "${repos[@]}"; do
    dnf5 -y copr enable $repo
done

niri_packages=(
"niri"
"xwayland-satellite"
"matugen"
"xdg-desktop-portal"
"wlsunset"
"cava"
"cliphist"
"ddcutil"
"brightnessctl"
"swww"
"qt6ct"
"qt5ct"
"nwg-look"
"nerd-fonts"
"quickshell"
"wlogout"
"niriswitcher"
"polkit-kde"
)

sysadmin_packages=(
  "libguestfs-tools"
  "NetworkManager-tui"
  "virt-install"
  "virt-manager"
  "virt-viewer"
)

programming_packages=(
  "code"
  "kitty"
)

utility_packages=(
  "scrcpy"
)

docker_packages=(
"docker-ce"
"docker-ce-cli"
"containerd.io"
"docker-buildx-plugin"
"docker-compose-plugin"
)

packages=(
  ${niri_packages[@]}
  ${sysadmin_packages[@]}
  ${programming_packages[@]}
  ${utility_packages[@]}
  ${docker_packages[@]}
)

# install rpms
rpm-ostree install ${packages[@]}

for repo in "${repos[@]}"; do
    dnf5 -y copr disable $repo
done

# install fzf-tab-completion
git clone https://github.com/lincheney/fzf-tab-completion.git /usr/share/ublue-os/fzf-tab-completion

# install noctalia-shell
mkdir -p /etc/xdg/quickshell/noctalia-shell/
curl -sL https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar.gz | \
tar -xz --strip-components=1 -C /etc/xdg/quickshell/noctalia-shell/



