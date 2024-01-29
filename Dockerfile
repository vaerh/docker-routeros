FROM alpine:3.19.1

LABEL maintainer="Vaerh <vaerh@tutanota.com>"

# For access via VNC
EXPOSE 5900

# Expose Ports of RouterOS
EXPOSE 1194 1701 1723 1812/udp 1813/udp 21 22 23 443 4500/udp 50 500/udp 51 2021 2022 2023 2027 5900 80 8080 8291 8728 8729 8900

# Change work dir (it will also create this folder if is not exist)
WORKDIR /routeros

# Install dependencies
RUN set -xe \
 && apk add --no-cache --update \
    netcat-openbsd qemu-x86_64 qemu-system-x86_64 \
    busybox-extras iproute2 iputils \
    bridge-utils iptables jq bash python3 \
    libarchive-tools


# Environments which may be change
ENV ROUTEROS_VERSION="7.13.3"
ENV ROUTEROS_IMAGE="chr-$ROUTEROS_VERSION.vdi"
ENV ROUTEROS_PATH="https://download.mikrotik.com/routeros/$ROUTEROS_VERSION/$ROUTEROS_IMAGE"

# Download VDI image from remote site
RUN wget -qO- "$ROUTEROS_PATH".zip | bsdtar -C /routeros/ -xf- || wget "$ROUTEROS_PATH" -O "/routeros/$ROUTEROS_IMAGE"

# Copy script to routeros folder
ADD ["./scripts", "/routeros"]

ENTRYPOINT ["/routeros/entrypoint.sh"]
