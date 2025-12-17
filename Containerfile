# Build context 

FROM scratch AS ctx
COPY system_files /
COPY scripts /

# Base Image
FROM ghcr.io/ublue-os/bazzite-gnome:latest AS okadora

# BUILD PHASE

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,target=/var/cache \
    --mount=type=cache,target=/var/log \
    --mount=type=tmpfs,target=/tmp \

    install -m755 /ctx/repository.sh /tmp/repository.sh && \
    install -m755 /ctx/install_packages.sh  /tmp/install_packages.sh  && \
    install -m755 /ctx/enable_services.sh /tmp/enable_services.sh && \
    install -m755 /ctx/nix-overlay-service.sh /tmp/nix-overlay-service.sh && \
    install -m755 /ctx/nix.sh /tmp/nix.sh && \
    install -m755 /ctx/custom.sh /tmp/custom.sh && \
    install -m755 /ctx/just.sh /tmp/just.sh && \

    
    install -Dm755 /ctx/okadoranix-helper.sh /usr/bin/okadoranix-helper && \
    install -Dm755 /ctx/mount-nix-overlay.sh /usr/bin/mount-nix-overlay.sh && \
    
    bash /tmp/repository.sh && \
    bash /tmp/install_packages.sh 
    bash /tmp/nix-overlay-service.sh && \
    bash /tmp/nix.sh && \
    bash /tmp/enable_services.sh && \
    bash /tmp/just.sh && \
    bash /tmp/custom.sh


    ostree container commit
