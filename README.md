# silverblue-43-xps15

Custom Fedora Silverblue 43 OCI image for Dell XPS 15 with NVIDIA GPU support.

## What's Included

### Layered Packages

- **NVIDIA drivers:** akmod-nvidia, akmods, xorg-x11-drv-nvidia, xorg-x11-drv-nvidia-cuda, nvidia-settings, libva-nvidia-driver
- **NVIDIA container support:** nvidia-container-toolkit
- **Multimedia codecs:** gstreamer1-plugin-openh264, gstreamer1-plugins-bad-freeworld, gstreamer1-plugins-ugly, libavcodec-freeworld, gstreamer-plugins-espeak
- **Desktop:** gnome-shell-extension-gsconnect, xcb-util-cursor, xcb-util-cursor-devel
- **Tools:** zsh, tmux, podlet
- **Gaming:** steam-devices

### NVIDIA Container GPU Passthrough

Custom systemd units are baked into the image:

- **nvidia-container-fix.service** — Relabels `/dev/nvidia*` with `container_file_t` SELinux context on boot so containers can access the GPU
- **nvidia-cdi-generate.timer** — Regenerates the NVIDIA CDI spec (`/etc/cdi/nvidia.yaml`) on boot and daily

## Usage

### Rebase a Fresh Silverblue Install

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/maciej-makowski/silverblue-43-xps15:latest
systemctl reboot
```

### Rollback to Stock Silverblue

```bash
rpm-ostree rebase fedora:fedora/43/x86_64/silverblue
systemctl reboot
```

## Building Locally

Requires the akmods signing keys at their default paths on the host:

```bash
podman build \
  --secret id=signing_pubkey,src=/etc/pki/akmods-keys/certs/public_key.der \
  --secret id=signing_privkey,src=/etc/pki/akmods-keys/private/private_key.priv \
  -t silverblue-43-xps15:latest .
```

## CI

GitHub Actions rebuilds the image daily at 05:00 UTC and on every push to `main`, then pushes to `ghcr.io/maciej-makowski/silverblue-43-xps15:latest`.

Signing keys are stored as GitHub secrets (`AKMODS_PUBKEY`, `AKMODS_PRIVKEY`), base64-encoded.

## Signing Key Management

The NVIDIA kernel modules must be signed for Secure Boot. Keys are generated on the target machine and enrolled in UEFI via `mokutil`.

### Rotating Keys

1. Generate new keys on the machine: `sudo kmodgenca`
2. Enroll the new public key: `sudo mokutil --import /etc/pki/akmods/certs/public_key.der`
3. Reboot and accept the key in the MOK manager
4. Upload new keys to GitHub secrets:
   ```bash
   sudo base64 -w0 /etc/pki/akmods-keys/certs/public_key.der | gh secret set AKMODS_PUBKEY --repo maciej-makowski/silverblue-43-xps15
   sudo base64 -w0 /etc/pki/akmods-keys/private/private_key.priv | gh secret set AKMODS_PRIVKEY --repo maciej-makowski/silverblue-43-xps15
   ```
5. Trigger a rebuild (push to `main` or manually trigger the workflow)
