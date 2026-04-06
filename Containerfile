FROM quay.io/fedora/fedora-silverblue:43

# Install RPM Fusion repositories
RUN rpm-ostree install \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm \
    && rpm-ostree cleanup -m

# Configure akmods signing key paths
COPY etc/rpm/macros.kmodtool /etc/rpm/macros.kmodtool

# Install all packages except akmod-nvidia (its post-install scriptlet
# tries to build the kmod as root, which akmods rejects, causing the
# entire rpm-ostree transaction to roll back)
RUN rpm-ostree install \
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

# Install akmod-nvidia and build the NVIDIA kernel module:
# 1. Download the akmod-nvidia RPM without installing
# 2. Extract it manually (just a src.rpm in /usr/src/akmods/)
# 3. Build the kmod as the akmods user with signing keys
RUN --mount=type=secret,id=signing_pubkey,dst=/etc/pki/akmods-keys/certs/public_key.der \
    --mount=type=secret,id=signing_privkey,dst=/etc/pki/akmods-keys/private/private_key.priv \
    dnf download --destdir=/tmp akmod-nvidia \
    && rpm -ivh --noscripts /tmp/akmod-nvidia-*.rpm \
    && runuser -u akmods -- akmods --force \
    && rm -f /tmp/akmod-nvidia-*.rpm

# Copy NVIDIA container support systemd units
COPY etc/systemd/system/nvidia-container-fix.service /etc/systemd/system/nvidia-container-fix.service
COPY etc/systemd/system/nvidia-cdi-generate.service /etc/systemd/system/nvidia-cdi-generate.service
COPY etc/systemd/system/nvidia-cdi-generate.timer /etc/systemd/system/nvidia-cdi-generate.timer
COPY opt/systemd/nvidia-container-fix.sh /opt/systemd/nvidia-container-fix.sh

# Enable the NVIDIA services
RUN chmod +x /opt/systemd/nvidia-container-fix.sh \
    && systemctl enable nvidia-container-fix.service \
    && systemctl enable nvidia-cdi-generate.timer
