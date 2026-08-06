#!/usr/bin/env bash
# deploy-docker-volume-backup.sh — Sync and start the docker-volume-backup container on docker-host.
# Usage:    bash systems/backups/scripts/deploy-docker-volume-backup.sh [--force]
# --force:  Recreate container even if the spec is unchanged.
# TARGET:   Override SSH target (default: admin@docker-host.local)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
source "${REPO_ROOT}/scripts/_deploy.sh"

WORKLOAD=backups
TARGET="${TARGET:-admin@docker-host.local}"
REMOTE_DIR="/opt/stacks/${WORKLOAD}"
FORCE=false; [[ "${1:-}" == "--force" ]] && FORCE=true

rsync_to "${REPO_ROOT}/systems/${WORKLOAD}/config/" "${TARGET}:${REMOTE_DIR}/"
rsync_to "${REPO_ROOT}/systems/${WORKLOAD}/scripts/" "${TARGET}:/tmp/backups-scripts/"

COMPOSE_FLAGS="up -d --remove-orphans"
$FORCE && COMPOSE_FLAGS="${COMPOSE_FLAGS} --force-recreate"
ssh_exec "${TARGET}" "cd ${REMOTE_DIR} && docker compose -p ${WORKLOAD} ${COMPOSE_FLAGS}"
ssh_exec "${TARGET}" "bash /tmp/backups-scripts/setup-heartbeat.sh"
