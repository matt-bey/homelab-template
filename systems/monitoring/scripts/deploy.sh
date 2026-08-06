#!/usr/bin/env bash
# deploy.sh — Sync and apply the monitoring stack on docker-host.
# Usage:    bash systems/monitoring/scripts/deploy.sh [--force]
# --force:  Recreate containers even if the spec is unchanged.
# TARGET:   Override SSH target (default: admin@docker-host.local)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "${REPO_ROOT}/scripts/_deploy.sh"

WORKLOAD=monitoring
TARGET="${TARGET:-admin@docker-host.local}"
REMOTE_DIR="/opt/stacks/${WORKLOAD}"
FORCE=false; [[ "${1:-}" == "--force" ]] && FORCE=true

rsync_to "${REPO_ROOT}/systems/${WORKLOAD}/config/" "${TARGET}:${REMOTE_DIR}/"

COMPOSE_FLAGS="up -d --remove-orphans"
$FORCE && COMPOSE_FLAGS="${COMPOSE_FLAGS} --force-recreate --pull always"
ssh_exec "${TARGET}" "cd ${REMOTE_DIR} && docker compose -p ${WORKLOAD} ${COMPOSE_FLAGS}"
