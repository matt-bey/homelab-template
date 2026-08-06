#!/usr/bin/env bash
# deploy.sh — Sync scripts to net-gateway and run the baseline bootstrap.
# Usage:    bash systems/net-gateway/scripts/deploy.sh [--force]
# --force:  Passed through to bootstrap.sh (no-op; script is always idempotent).
# TARGET:   Override SSH target (default: root@net-gateway.local)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "${REPO_ROOT}/scripts/_deploy.sh"

TARGET="${TARGET:-root@net-gateway.local}"
REMOTE_DIR="/opt/net-gateway"
FORCE=false; [[ "${1:-}" == "--force" ]] && FORCE=true

rsync_to "${REPO_ROOT}/systems/net-gateway/scripts/" "${TARGET}:${REMOTE_DIR}/"

FORCE_FLAG=""; $FORCE && FORCE_FLAG="--force"
ssh_exec "${TARGET}" "bash ${REMOTE_DIR}/bootstrap.sh ${FORCE_FLAG}"
