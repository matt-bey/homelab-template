#!/usr/bin/env bash
# deploy.sh — Sync tailscale scripts to net-gateway and run the subnet router setup.
# Usage:    bash systems/tailscale/scripts/deploy.sh [--force]
# --force:  Passed through to setup-subnet-router.sh (re-runs tailscale up).
# TARGET:   Override SSH target (default: root@net-gateway.local)
#
# Installs tailscale and configures net-gateway as the Core/Clients/IoT subnet
# router. After first run, approve the routes in the Tailscale admin panel.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "${REPO_ROOT}/scripts/_deploy.sh"

TARGET="${TARGET:-root@net-gateway.lab.yourdomain.com}"
REMOTE_DIR="/opt/tailscale"
FORCE=false; [[ "${1:-}" == "--force" ]] && FORCE=true

rsync_to "${REPO_ROOT}/systems/tailscale/scripts/" "${TARGET}:${REMOTE_DIR}/"

FORCE_FLAG=""; $FORCE && FORCE_FLAG="--force"
ssh_exec "${TARGET}" "bash ${REMOTE_DIR}/setup-subnet-router.sh ${FORCE_FLAG}"
