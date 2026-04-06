# Rebase Guide

## Before you start

### 1. Pin your current deployment

This prevents the current working deployment from being garbage collected while you experiment:

```bash
sudo ostree admin pin 0
```

Verify it's pinned:

```bash
rpm-ostree status
```

You should see `pinned: yes` on the current deployment.

### 2. Note your current refspec

```
fedora:fedora/43/x86_64/silverblue
```

## Rebase to the custom image

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/maciej-makowski/silverblue-43-xps15:latest
systemctl reboot
```

After reboot, verify you're running the custom image:

```bash
rpm-ostree status
```

The origin should show `ostree-unverified-registry:ghcr.io/maciej-makowski/silverblue-43-xps15:latest`.

## Rolling back

### Option A: Select previous deployment at boot

GRUB shows the previous deployment in its menu. Select it to boot into your pinned stock Silverblue deployment.

### Option B: Rollback from a running system

```bash
rpm-ostree rollback
systemctl reboot
```

### Option C: Rebase back to stock Silverblue

```bash
rpm-ostree rebase fedora:fedora/43/x86_64/silverblue
systemctl reboot
```

## After successful testing

Once you're happy the custom image works correctly, unpin the old deployment:

```bash
sudo ostree admin pin --unpin 1
```

(Use `rpm-ostree status` to check which index the pinned deployment is at — it may be `1` or `2` depending on how many deployments exist.)
