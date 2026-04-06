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
# packages and install with --noscripts to skip the scriptlet, then build
# the kmod RPM as the akmods user using akmodsbuild, and install it.
RUN --mount=type=secret,id=signing_pubkey,dst=/tmp/signing_pubkey \
    --mount=type=secret,id=signing_privkey,dst=/tmp/signing_privkey \
    dnf download --resolve --destdir=/tmp/nvidia-rpms \
        akmod-nvidia \
        xorg-x11-drv-nvidia \
        xorg-x11-drv-nvidia-cuda \
        nvidia-settings \
        libva-nvidia-driver \
    && rpm -ivh --noscripts --nodeps /tmp/nvidia-rpms/*.rpm \
    && mkdir -p /etc/pki/akmods-keys/certs /etc/pki/akmods-keys/private /tmp/nvidia-kmod \
    && cp /tmp/signing_pubkey /etc/pki/akmods-keys/certs/public_key.der \
    && cp /tmp/signing_privkey /etc/pki/akmods-keys/private/private_key.priv \
    && chmod 644 /etc/pki/akmods-keys/certs/public_key.der \
    && chmod 644 /etc/pki/akmods-keys/private/private_key.priv \
    && chown -R akmods:akmods /tmp/nvidia-kmod \
    && KERNEL_VERSION=$(ls /usr/src/kernels/ | head -1) \
    && runuser -u akmods -- akmodsbuild \
        --kernels "$KERNEL_VERSION" \
        --outputdir /tmp/nvidia-kmod \
        /usr/src/akmods/nvidia-kmod.latest \
    && rpm -ivh --noscripts --nodeps /tmp/nvidia-kmod/*.rpm \
    && rm -rf /tmp/nvidia-rpms /tmp/nvidia-kmod \
       /etc/pki/akmods-keys/private/private_key.priv

# Copy NVIDIA container support systemd units
COPY etc/systemd/system/nvidia-container-fix.service /etc/systemd/system/nvidia-container-fix.service
COPY etc/systemd/system/nvidia-cdi-generate.service /etc/systemd/system/nvidia-cdi-generate.service
COPY etc/systemd/system/nvidia-cdi-generate.timer /etc/systemd/system/nvidia-cdi-generate.timer
COPY opt/systemd/nvidia-container-fix.sh /opt/systemd/nvidia-container-fix.sh

# Enable the NVIDIA services
RUN chmod +x /opt/systemd/nvidia-container-fix.sh \
    && systemctl enable nvidia-container-fix.service \
    && systemctl enable nvidia-cdi-generate.timer
