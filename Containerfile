ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-gnome:latest
# Build context 

FROM scratch AS ctx
COPY system_files /system_files
COPY scripts /scripts


# Base Image
FROM ${BASE_IMAGE} AS Okadora

COPY --from=ctx /system_files /
RUN mkdir -p /usr/share/ublue-os/just
COPY system_files/usr/share/ublue-os/just/60-okadora.just /usr/share/ublue-os/just/60-okadora.just
RUN chmod 644 /usr/share/ublue-os/just/60-okadora.just

# OPT preparation

RUN rm -rf /opt && mkdir /opt


# BUILD PHASE
RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,target=/var/cache \
    --mount=type=cache,target=/var/log \
    --mount=type=tmpfs,target=/tmp \
    install -m755 /ctx/scripts/repository.sh /tmp/repository.sh && \
    install -m755 /ctx/scripts/install_packages.sh /tmp/install_packages.sh && \
    install -m755 /ctx/scripts/enable_services.sh /tmp/enable_services.sh && \
    install -m755 /ctx/scripts/nix-overlay-service.sh /tmp/nix-overlay-service.sh && \
    install -m755 /ctx/scripts/nix.sh /tmp/nix.sh && \
    install -m755 /ctx/scripts/custom.sh /tmp/custom.sh && \
    install -Dm755 /ctx/scripts/okadoranix-helper.sh /usr/bin/okadoranix-helper && \
    install -Dm755 /ctx/scripts/mount-nix-overlay.sh /usr/bin/mount-nix-overlay.sh && \
    install -Dm755 /ctx/scripts/force-niri-session.sh /usr/bin/force-niri-session.sh && \
    bash /tmp/repository.sh && \
    bash /tmp/install_packages.sh && \
    bash /tmp/nix-overlay-service.sh && \
    bash /tmp/nix.sh && \
    bash /tmp/enable_services.sh && \
    bash /tmp/custom.sh && \
    rm -rf /system_files && \
    rpm-ostree cleanup -m && \
    rm -rf /var/cache/dnf/* && \
    rm -rf /var/cache/rpm-ostree/* && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/* 

# ADDING FLATHUB SYSTEM
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# UPDATE DCONF
RUN dconf update || true

RUN cat > /usr/lib/tmpfiles.d/okadora-var.conf << 'EOF'
d /var/lib/dnf 0755 root root - -
d /var/lib/dnf/repos 0755 root root - -
d /var/lib/flatpak 0755 root root - -
EOF


# Enable force niri session
RUN systemctl enable force-niri-session.service

# Enable okadora firstboot service
RUN systemctl enable okadora-firstboot.service
RUN systemctl --global enable okadora-user-setup.service


# Container verification

RUN bootc container lint