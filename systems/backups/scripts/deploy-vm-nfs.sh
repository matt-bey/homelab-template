#!/usr/bin/env bash
# deploy.sh — Set up backup NFS infrastructure on homelab-server and docker-host.
# Usage: bash systems/backups/scripts/deploy.sh
#
# Environment overrides:
#   PROXMOX_HOST        SSH target for homelab-server  (default: root@<homelab-server-ip>)
#   DOCKER_HOST_TARGET  SSH target for docker-host     (default: admin@docker-host.local)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "${REPO_ROOT}/scripts/_deploy.sh"

PROXMOX_HOST="${PROXMOX_HOST:-root@<homelab-server-ip>}"
DOCKER_HOST_TARGET="${DOCKER_HOST_TARGET:-admin@docker-host.local}"
SCRIPTS_DIR="${REPO_ROOT}/systems/backups/scripts"

echo "==> Phase 1: NFS export on homelab-server"
rsync_to "${SCRIPTS_DIR}/" "${PROXMOX_HOST}:/tmp/backups-scripts/"
ssh_exec "${PROXMOX_HOST}" "bash /tmp/backups-scripts/setup-nfs-export.sh"

echo "==> Phase 2: NFS mount on docker-host"
rsync_to "${SCRIPTS_DIR}/" "${DOCKER_HOST_TARGET}:/tmp/backups-scripts/"
ssh_exec "${DOCKER_HOST_TARGET}" "sudo bash /tmp/backups-scripts/setup-nfs-mount.sh"

echo "==> Backup NFS infrastructure deployed"
