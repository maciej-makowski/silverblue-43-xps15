FROM quay.io/fedora/fedora-silverblue:43

# Install RPM Fusion repositories
RUN rpm-ostree install \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-43.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-43.noarch.rpm \
    && rpm-ostree cleanup -m

# Configure akmods signing key paths
COPY etc/rpm/macros.kmodtool /etc/rpm/macros.kmodtool

# Install non-NVIDIA packages via rpm-ostree
RUN rpm-ostree install \
        akmods \
        gnome-shell-extension-gsconnect \
        gstreamer-plugins-espeak \
        gstreamer1-plugin-openh264 \
        gstreamer1-plugins-bad-freeworld \
        gstreamer1-plugins-ugly \
        libavcodec-freeworld \
        nvidia-container-toolkit \
        podlet \
        steam-devices \
        tmux \
        xcb-util-cursor \
        xcb-util-cursor-devel \
        zsh \
    && rpm-ostree cleanup -m

# Install NVIDIA driver packages. These depend on nvidia-kmod (provided by
# akmod-nvidia), whose post-install scriptlet fails as root. We download all
# packages and install with --noscripts, then build the kmod manually.
RUN --mount=type=secret,id=signing_pubkey,dst=/etc/pki/akmods-keys/certs/public_key.der \
    --mount=type=secret,id=signing_privkey,dst=/etc/pki/akmods-keys/private/private_key.priv \
    dnf download --resolve --destdir=/tmp/nvidia-rpms \
        akmod-nvidia \
        xorg-x11-drv-nvidia \
        xorg-x11-drv-nvidia-cuda \
        nvidia-settings \
        libva-nvidia-driver \
    && rpm -ivh --noscripts --nodeps /tmp/nvidia-rpms/*.rpm \
    && runuser -u akmods -- akmods --force \
    && rm -rf /tmp/nvidia-rpms

# Copy NVIDIA container support systemd units
COPY etc/systemd/system/nvidia-container-fix.service /etc/systemd/system/nvidia-container-fix.service
COPY etc/systemd/system/nvidia-cdi-generate.service /etc/systemd/system/nvidia-cdi-generate.service
COPY etc/systemd/system/nvidia-cdi-generate.timer /etc/systemd/system/nvidia-cdi-generate.timer
COPY opt/systemd/nvidia-container-fix.sh /opt/systemd/nvidia-container-fix.sh

# Enable the NVIDIA services
RUN chmod +x /opt/systemd/nvidia-container-fix.sh \
    && systemctl enable nvidia-container-fix.service \
    && systemctl enable nvidia-cdi-generate.timer
