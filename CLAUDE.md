# Silverblue 43 Custom Image

This repo builds a custom Fedora Silverblue 43 OCI image for a Dell XPS 15.

- Base: `quay.io/fedora/fedora-silverblue:43`
- Registry: `ghcr.io/maciej-makowski/silverblue-43-xps15`
- Rebase command: `rpm-ostree rebase ostree-unverified-registry:ghcr.io/maciej-makowski/silverblue-43-xps15:latest`
- Rollback refspec: `fedora:fedora/43/x86_64/silverblue`
- CI: GitHub Actions rebuilds daily at 05:00 UTC and on push to `main`

## Build Architecture

Multi-stage Containerfile:
- **Stage 1 (`kmod-builder`):** Builds and signs the NVIDIA kernel module using `akmodsbuild` as the `akmods` user. This is needed because `akmods` refuses to run as root, causing `rpm-ostree install` to fail in container builds.
- **Stage 2 (final):** Installs all packages, copies the pre-built kmod RPM from stage 1, installs NVIDIA drivers via `rpm --noscripts --nodeps`. No build tooling in the final image.

## Signing Keys

NVIDIA kernel modules are signed for Secure Boot. Keys are stored as base64-encoded GitHub secrets (`AKMODS_PUBKEY`, `AKMODS_PRIVKEY`). At build time, they're mounted via `--secret`, copied to paths readable by the `akmods` user for module signing, then removed. The private key never persists in any image layer.

## Building Locally

```bash
podman build \
  --secret id=signing_pubkey,src=/etc/pki/akmods-keys/certs/public_key.der \
  --secret id=signing_privkey,src=/etc/pki/akmods-keys/private/private_key.priv \
  -t silverblue-43-xps15:latest .
```

From inside a toolbox, use `podman --remote build` with keys copied to `/tmp/` (see README.md).

## Package Management

When helping the user install packages on the base OS (via `rpm-ostree install`), always recommend also adding them to the Containerfile so they're baked into the next image build. Layered packages work but add runtime overhead and can conflict with future image updates.

## Git Workflow

- All changes via PR to `main` (squash merge only)
- Use `toolbox run git` for git commands (git is configured in toolbox, not on host)
- Use `toolbox run gh` for GitHub CLI commands
