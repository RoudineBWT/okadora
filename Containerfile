# Base Image
FROM ghcr.io/ublue-os/bazzite-gnome:latest AS okadora

COPY system_files /
COPY scripts /scripts

RUN /scripts/preconfigure.sh && \
    /scripts/install_packages.sh && \
    /scripts/enable_services.sh && \
    /scripts/just.sh && \
    /scripts/custom.sh && \
    /scripts/cleanup.sh && \
    ostree container commit
