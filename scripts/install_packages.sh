#!/bin/bash

set -ouex pipefail
repos=(
    solopasha/hyprland
    errornointernet/quickshell
    che/nerd-fonts
    scottames/ghostty
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
"polkit-kde"
"kf5-kirigami2"
"kf6-kirigami"
"qt6-qtdeclarative"
)

programming_packages=(
  "code"
  "ghostty"
)


packages=(
  ${niri_packages[@]}
  ${programming_packages[@]}
)

# install rpms
rpm-ostree install ${packages[@]}

# niri testing (when needed)
#sed -i 's/enabled=0/enabled=1/' /etc/yum.repos.d/fedora-updates-testing.repo
#rpm-ostree install niri
#sed -i 's/enabled=1/enabled=0/' /etc/yum.repos.d/fedora-updates-testing.repo


for repo in "${repos[@]}"; do
    dnf5 -y copr disable $repo
done

# install fzf-tab-completion
git clone https://github.com/lincheney/fzf-tab-completion.git /usr/share/ublue-os/fzf-tab-completion

# install noctalia-shell
mkdir -p /etc/xdg/quickshell/noctalia-shell/
curl -sL https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar.gz | \
tar -xz --strip-components=1 -C /etc/xdg/quickshell/noctalia-shell/
