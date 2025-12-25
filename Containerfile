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
    install -m755 /ctx/scripts/nix.sh /tmp/nix.sh && \
    install -m755 /ctx/scripts/kernel-cachyos.sh /tmp/kernel-cachyos.sh && \
    install -m755 /ctx/scripts/dracut.sh /tmp/dracut.sh && \
    install -m755 /ctx/scripts/enable_services.sh /tmp/enable_services.sh && \
    install -Dm755 /ctx/scripts/okadoranix-helper.sh /usr/bin/okadoranix-helper && \
    install -Dm755 /ctx/scripts/force-niri-session.sh /usr/bin/force-niri-session.sh && \

    bash /tmp/repository.sh && \
    bash /tmp/install_packages.sh && \
    bash /tmp/nix.sh && \
    bash /tmp/kernel-cachyos.sh && \
    bash /tmp/dracut.sh && \
    bash /tmp/enable_services.sh && \
    # cleanup
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

# Enable force niri session
RUN systemctl enable force-niri-session.service

# Enable okadora firstboot service
RUN systemctl enable okadora-firstboot.service
RUN systemctl --global enable okadora-user-setup.service

# CUSTOM BRANDING - Install service, script and apply branding
COPY system_files/usr/lib/systemd/system/okadora-branding.service /usr/lib/systemd/system/okadora-branding.service
COPY scripts/okadora-branding.sh /tmp/okadora-branding.sh
COPY scripts/custom.sh /tmp/custom.sh
RUN chmod 644 /usr/lib/systemd/system/okadora-branding.service && \
    chmod +x /tmp/custom.sh && \
    chmod +x /tmp/okadora-branding.sh && \
    install -Dm755 /tmp/okadora-branding.sh /usr/bin/okadora-branding.sh && \
    bash /tmp/custom.sh && \
    rm -f /tmp/custom.sh /tmp/okadora-branding.sh

# Enable okadora branding service (runs at every boot)
RUN systemctl enable okadora-branding.service

# Container verification

RUN bootc container lint
