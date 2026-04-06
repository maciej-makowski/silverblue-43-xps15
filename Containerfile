FROM quay.io/fedora/fedora-silverblue:43

# Install RPM Fusion repositories
RUN rpm-ostree install \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm \
    && rpm-ostree cleanup -m

# Configure akmods signing key paths
COPY etc/rpm/macros.kmodtool /etc/rpm/macros.kmodtool

# Install layered packages with signing keys mounted (not persisted in image)
RUN --mount=type=secret,id=signing_pubkey,dst=/etc/pki/akmods-keys/certs/public_key.der \
    --mount=type=secret,id=signing_privkey,dst=/etc/pki/akmods-keys/private/private_key.priv \
    rpm-ostree install \
        akmod-nvidia \
        akmods \
        gnome-shell-extension-gsconnect \
        gstreamer-plugins-espeak \
        gstreamer1-plugin-openh264 \
        gstreamer1-plugins-bad-freeworld \
        gstreamer1-plugins-ugly \
        libavcodec-freeworld \
        libva-nvidia-driver \
        nvidia-container-toolkit \
        nvidia-settings \
        podlet \
        steam-devices \
        tmux \
        xcb-util-cursor \
        xcb-util-cursor-devel \
        xorg-x11-drv-nvidia \
        xorg-x11-drv-nvidia-cuda \
        zsh \
    && rpm-ostree cleanup -m

# Build NVIDIA kernel module (akmods refuses to run as root)
RUN --mount=type=secret,id=signing_pubkey,dst=/etc/pki/akmods-keys/certs/public_key.der \
    --mount=type=secret,id=signing_privkey,dst=/etc/pki/akmods-keys/private/private_key.priv \
    runuser -u akmods -- akmods --force

# Copy NVIDIA container support systemd units
COPY etc/systemd/system/nvidia-container-fix.service /etc/systemd/system/nvidia-container-fix.service
COPY etc/systemd/system/nvidia-cdi-generate.service /etc/systemd/system/nvidia-cdi-generate.service
COPY etc/systemd/system/nvidia-cdi-generate.timer /etc/systemd/system/nvidia-cdi-generate.timer
COPY opt/systemd/nvidia-container-fix.sh /opt/systemd/nvidia-container-fix.sh

# Enable the NVIDIA services
RUN chmod +x /opt/systemd/nvidia-container-fix.sh \
    && systemctl enable nvidia-container-fix.service \
    && systemctl enable nvidia-cdi-generate.timer
