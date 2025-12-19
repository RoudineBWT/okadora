ARG BASE_IMAGE=ghcr.io/ublue-os/bazzite-gnome:latest
# Build context 

FROM scratch AS ctx
COPY system_files /system_files
COPY scripts /scripts
COPY files /files

# Base Image
FROM ${BASE_IMAGE}

COPY --from=ctx /system_files /
COPY --from=ctx /files /tmp/okadora-files

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
    install -m755 /ctx/scripts/just.sh /tmp/just.sh && \
    install -Dm755 /ctx/scripts/okadoranix-helper.sh /usr/bin/okadoranix-helper && \
    install -Dm755 /ctx/scripts/mount-nix-overlay.sh /usr/bin/mount-nix-overlay.sh && \
    bash /tmp/repository.sh && \
    bash /tmp/install_packages.sh && \
    bash /tmp/nix-overlay-service.sh && \
    bash /tmp/nix.sh && \
    bash /tmp/enable_services.sh && \
    bash /tmp/just.sh && \
    bash /tmp/custom.sh && \
    install -Dm644 /tmp/okadora-files/okadora-firstboot.service /usr/etc/systemd/user/okadora-firstboot.service && \
    install -Dm755 /tmp/okadora-files/okadora-firstboot-setup /usr/libexec/okadora-firstboot-setup && \
    mkdir -p /var/lib/okadora && \
    systemctl --global enable okadora-firstboot.service && \
    rm -rf /system_files && \
    rpm-ostree cleanup -m && \
     rm -rf /var/cache/dnf/* && \
    rm -rf /var/cache/rpm-ostree/* && \
    rm -rf /var/tmp/* && \
    rm -rf /tmp/* && \
    ostree container commit
