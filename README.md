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

*** You will need to click on the gear icon ⚙️ in gdm and select niri instead of gnome. I can't get gdm to use niri by default. ***


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

-----

- Special Thanks to [#Universal-Blue](https://github.com/ublue-os) and their efforts to improve Linux Desktop.
- Thanks to [#Fedora](https://fedoraproject.org/fr/) and the [#atomic-project](https://fedoramagazine.org/introducing-fedora-atomic-desktops/) upstream
- If you have time, check out [#Bluefin](https://projectbluefin.io/) or [#Bazzite](https://bazzite.gg/) and support them.
