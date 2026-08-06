#!/usr/bin/env bash
# setup-nfs-mount.sh — Idempotent. Mounts the NFS backup share from homelab-server
# inside docker-host. Run as root (called via sudo by deploy.sh).
#
# Environment overrides:
#   NFS_SERVER    IP of the NFS server           (default: <homelab-server-ip>)
#   NFS_EXPORT    Export path on the server      (default: /backups/c2volumes)
#   MOUNT_POINT   Local mount point              (default: /mnt/backups)
set -euo pipefail

NFS_SERVER="${NFS_SERVER:-<homelab-server-ip>}"
NFS_EXPORT="${NFS_EXPORT:-/backups/c2volumes}"
MOUNT_POINT="${MOUNT_POINT:-/mnt/backups}"

# Install NFS client
if ! dpkg -s nfs-common &>/dev/null; then
    echo "==> Installing nfs-common"
    apt-get install -y nfs-common
else
    echo "==> nfs-common already installed"
fi

# Create mount point
if [ ! -d "${MOUNT_POINT}" ]; then
    echo "==> Creating ${MOUNT_POINT}"
    mkdir -p "${MOUNT_POINT}"
fi

# Add fstab entry
FSTAB_ENTRY="${NFS_SERVER}:${NFS_EXPORT} ${MOUNT_POINT} nfs defaults,_netdev 0 0"
if ! grep -qF "${NFS_SERVER}:${NFS_EXPORT}" /etc/fstab; then
    echo "==> Adding fstab entry"
    echo "${FSTAB_ENTRY}" >> /etc/fstab
else
    echo "==> fstab entry already present"
fi

# Mount if not already mounted
if ! mountpoint -q "${MOUNT_POINT}"; then
    echo "==> Mounting ${MOUNT_POINT}"
    mount "${MOUNT_POINT}"
else
    echo "==> ${MOUNT_POINT} already mounted"
fi

echo "==> Done: ${NFS_SERVER}:${NFS_EXPORT} mounted at ${MOUNT_POINT}"
