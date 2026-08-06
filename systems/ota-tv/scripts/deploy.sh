#!/usr/bin/env bash
# deploy.sh — Sync and apply the ota-tv stack (HDHomeRun signal probe) on
#             docker-host. Idempotent: safe to run repeatedly.
# Usage:    bash systems/ota-tv/scripts/deploy.sh [--force]
# --force:  Recreate containers even if the spec is unchanged.
# TARGET:   Override SSH target (default: admin@docker-host.local)
#
# The image is built locally on docker-host (the probe ships hdhomerun_config +
# probe.py), so this always passes --build: a rebuild is cache-fast when nothing
# changed and picks up probe.py edits when something did. Depends on the
# pushgateway service in the monitoring stack — deploy that first.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "${REPO_ROOT}/scripts/_deploy.sh"

WORKLOAD=ota-tv
TARGET="${TARGET:-admin@docker-host.local}"
REMOTE_DIR="/opt/stacks/${WORKLOAD}"
FORCE=false; [[ "${1:-}" == "--force" ]] && FORCE=true

rsync_to "${REPO_ROOT}/systems/${WORKLOAD}/config/" "${TARGET}:${REMOTE_DIR}/"

COMPOSE_FLAGS="up -d --remove-orphans --build"
$FORCE && COMPOSE_FLAGS="${COMPOSE_FLAGS} --force-recreate"
ssh_exec "${TARGET}" "cd ${REMOTE_DIR} && docker compose -p ${WORKLOAD} ${COMPOSE_FLAGS}"
