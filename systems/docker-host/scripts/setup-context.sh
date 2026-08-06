#!/usr/bin/env bash
# setup-context.sh — Register the docker-host Docker context on this machine.
# Run once per machine (dev-workstation, MacBook). Idempotent.
# Usage: bash systems/docker-host/scripts/setup-context.sh
#
# Environment overrides:
#   CONTEXT_NAME      Docker context name  (default: docker-host)
#   DOCKER_HOST_SSH   SSH target           (default: admin@docker-host.local)
set -euo pipefail

CONTEXT_NAME="${CONTEXT_NAME:-docker-host}"
DOCKER_HOST_SSH="${DOCKER_HOST_SSH:-admin@docker-host.local}"

if docker context inspect "${CONTEXT_NAME}" &>/dev/null; then
    echo "==> Context '${CONTEXT_NAME}' already exists — skipping"
else
    echo "==> Creating Docker context '${CONTEXT_NAME}'"
    docker context create "${CONTEXT_NAME}" \
        --description "docker-host VM (<docker-host-ip>) on homelab-server" \
        --docker "host=ssh://${DOCKER_HOST_SSH}"
    echo "==> Done"
fi

echo ""
echo "    Deploy a workload (from repo root):"
echo "      DOCKER_CONTEXT=${CONTEXT_NAME} docker compose -p <workload> -f systems/<workload>/config/compose.yaml up -d"
echo ""
echo "    Or set as the active context for the current shell session:"
echo "      docker context use ${CONTEXT_NAME}"
echo "      docker context use default   # to switch back"
