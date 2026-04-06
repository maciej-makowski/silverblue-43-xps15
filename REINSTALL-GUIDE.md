# Reinstall Guide

Full reinstall of Fedora Silverblue with LUKS encryption and custom image restore.

## Prerequisites

Before reinstalling, ensure you have:

- [ ] Home directory backup on an external drive (`home-backup-YYYY-MM-DD.tar.zst`)
- [ ] This repo cloned or accessible (contains restore scripts and image config)
- [ ] Fedora Silverblue USB installer (download from https://fedoraproject.org/silverblue/)
- [ ] LUKS passphrase chosen

## Step 1: Install Fedora Silverblue

1. Boot from the Fedora Silverblue USB
2. In the Anaconda installer, select your disk
3. Choose **"Custom"** partitioning
4. Check **"Encrypt my data"** and set a LUKS passphrase
5. Create the partition layout:
   - `/boot/efi` — 600 MB, EFI System Partition
   - `/boot` — 1 GB, ext4, unencrypted (GRUB must read this)
   - LUKS-encrypted volume group with:
     - `/` — 70–100 GB, ext4
     - `/home` — remainder of disk, ext4
     - `swap` — 8–16 GB (optional, recommended for hibernate)
6. Complete the install and reboot

## Step 2: Rebase to custom image

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/maciej-makowski/silverblue-43-xps15:latest
systemctl reboot
```

## Step 3: Verify NVIDIA

```bash
nvidia-smi
```

If it fails, check `dmesg | grep nvidia`. If the CDI spec is stale:

```bash
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

## Step 4: Restore home directory

Mount the external drive and extract the backup:

```bash
cd /home
sudo tar xf /run/media/$USER/<drive>/home-backup-YYYY-MM-DD.tar.zst --use-compress-program='zstd -d'
sudo chown -R cfiet:cfiet /home/cfiet
```

## Step 5: Restore flatpaks and toolboxes

Clone this repo (or copy from the external drive):

```bash
git clone https://github.com/maciej-makowski/silverblue-43-xps15.git
cd silverblue-43-xps15
./restore/restore.sh
```

## Step 6: Configure toolbox

```bash
toolbox run git config --global user.name "Maciej Makowski"
toolbox run git config --global user.email "makowski@maciej.dev"
toolbox run gh auth login
```

## Step 7: Enable automatic updates

```bash
sudo tee /etc/rpm-ostreed.conf <<'EOF'
[Daemon]
AutomaticUpdatePolicy=stage
EOF
sudo systemctl enable --now rpm-ostreed-automatic.timer
```

## Step 8: Enrol signing keys (if Secure Boot)

If you need to rebuild the image locally or the MOK is not enrolled:

```bash
sudo mokutil --import /etc/pki/akmods/certs/public_key.der
```

Reboot and accept the key in the MOK manager.
