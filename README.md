# Okadora
![Screenshot of Okadora](assets/okadora.png)
[Bazzite Gnome](https://github.com/ublue-os/bazzite) Based Image but with [Niri Window Manager](https://github.com/YaLTeR/niri) and [Noctalia](https://github.com/noctalia-dev/noctalia-shell).
I'm using the container file from [DXC-0](https://github.com/DXC-0/daemonix/tree/main) for Nix integration, so please support him!

## Installation

> **Note** : This image is experimental and build for testing pruposes, When starting up, you will need to wait approximately 5 minutes for the initial configuration to complete.  

Rebase from any Fedora Atomic based distro :

```
sudo bootc switch ghcr.io/roudinebwt/okadora:latest
```

If you have a Nvidia GPU use this one :
```
sudo bootc switch ghcr.io/roudinebwt/okadora-nvidia:latest
```

To use any additionnal feature use : 

```
okadoranix-helper
```

Manually add nixpkgs unstable channel : 

```
nix-channel --add https://nixos.org/channels/nixpkgs-unstable nixpkgs
nix-channel --update
```

Documentation : [Nix-Determinate](https://docs.determinate.systems/determinate-nix/), [Homemanager](https://nix-community.github.io/home-manager/), [Flakes](https://zero-to-nix.com/concepts/flakes/)  



## 📁 File Structure

```
.config/niri/
├── cfg/
│   ├── animation.kdl      # Animation settings
│   ├── autostart.kdl      # Autostart applications
│   ├── display.kdl        # Display configuration
│   ├── input.kdl          # Input devices configuration
│   ├── keybinds.kdl       # Keyboard shortcuts
│   ├── layout.kdl         # Window layout configuration
│   ├── misc.kdl           # Miscellaneous options
│   └── rules.kdl          # Window rules
├── config.kdl             # Main configuration file
└── noctalia.kdl           # Noctalia theme configuration
```

> **Note** : When you will change the predefined colors schemes, you will need type **noctalia-sync** in Ghostty

## Packages

In addition to the packages included in [Bazzite](https://github.com/ublue-os/bazzite), I include the following installed by default:

### Layered Packages (through RPM-Ostree)

#### Desktop

- niri
- matugen
- xwayland-satelitte
- xdg-desktop-portal
- wlsunset
- cava
- cliphist
- ddcutil
- brightnessctl
- swww
- qt6ct
- qt5ct
- nwg-look
- nerd-fonts
- quickshell
- wlogout
- mate-polkit

#### Programming

- VSCode
- Ghostty

### Git Repositories (simple clone)

- [FZF-Tab-Completion](https://github.com/lincheney/fzf-tab-completion)
- [Noctalia-shell](https://github.com/noctalia-dev/noctalia-shell/releases/latest/download/noctalia-latest.tar)

### System Flatpaks

#### Browser

- Firefox

#### Communications

- Element
- Telegram

#### Multimedia

- Showtime
- Amberol

#### Design

- Gimp

### User Flatpaks

#### Communications

- Discord (using Vesktop)

#### Multimedia

- Spotify
- Stremio
- OBS Studio
- OBS DroidCam Plugin
- GPU Screen Recorder
- Parabolic 

#### Programming

- Podman Desktop

#### Gaming

- Heroic Games Launcher
- Prismlauncher

-----

- Special Thanks to [#Universal-Blue](https://github.com/ublue-os) and their efforts to improve Linux Desktop.
- Thanks to [#Fedora](https://fedoraproject.org/fr/) and the [#atomic-project](https://fedoramagazine.org/introducing-fedora-atomic-desktops/) upstream
- If you have time, check out [#Bluefin](https://projectbluefin.io/) or [#Bazzite](https://bazzite.gg/) and support them.
