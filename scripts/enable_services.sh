#!/bin/bash

set -ouex pipefail

systemctl enable docker.socket
systemctl enable podman.socket
systemctl enable nix-daemon.service