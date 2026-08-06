#!/usr/bin/env bash
# setup-nfs-export.sh — Idempotent. Creates the ZFS dataset and NFS export for C2
# volume backups. Run on homelab-server as root (called by deploy.sh).
#
# Environment overrides:
#   ZFS_DATASET   ZFS dataset to create          (default: backups/c2volumes)
#   NFS_CLIENT    IP allowed to mount the share  (default: <docker-host-ip>)
set -euo pipefail

ZFS_DATASET="${ZFS_DATASET:-backups/c2volumes}"
NFS_CLIENT="${NFS_CLIENT:-<docker-host-ip>}"
EXPORT_PATH="/${ZFS_DATASET}"

# Create ZFS dataset
if ! zfs list "${ZFS_DATASET}" &>/dev/null; then
    echo "==> Creating ZFS dataset ${ZFS_DATASET}"
    zfs create "${ZFS_DATASET}"
else
    echo "==> ${ZFS_DATASET} already exists"
fi

# Install NFS server
if ! dpkg -s nfs-kernel-server &>/dev/null; then
    echo "==> Installing nfs-kernel-server"
    apt-get install -y nfs-kernel-server
else
    echo "==> nfs-kernel-server already installed"
fi

# Add export entry
EXPORT_LINE="${EXPORT_PATH} ${NFS_CLIENT}(rw,sync,no_subtree_check,no_root_squash)"
if ! grep -qF "${EXPORT_PATH}" /etc/exports; then
    echo "==> Adding NFS export"
    echo "${EXPORT_LINE}" >> /etc/exports
else
    echo "==> NFS export already in /etc/exports"
fi

systemctl enable --now nfs-server
exportfs -ra

echo "==> Done: ${EXPORT_PATH} exported to ${NFS_CLIENT}"
