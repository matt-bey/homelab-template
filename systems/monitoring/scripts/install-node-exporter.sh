#!/usr/bin/env bash
# install-node-exporter.sh — install prometheus-node-exporter on a Debian/Proxmox host.
# Run as root on homelab-server. Idempotent — safe to re-run.
#
# This is Phase A.2 of systems/monitoring/plan.md: a bare-metal exporter that
# exposes the Proxmox host's view of the world (LVM-thin pool fill, host RAM,
# host disk) alongside the in-VM exporter that runs as a container on docker-host.
set -euo pipefail

PORT="${NODE_EXPORTER_PORT:-9100}"

echo "==> Updating apt index"
apt-get update -q

echo "==> Installing prometheus-node-exporter"
apt-get install -y prometheus-node-exporter

echo "==> Ensuring unit is enabled and running"
systemctl enable --now prometheus-node-exporter

echo "==> Verifying listener on :${PORT}"
# ss is part of iproute2 and present on every Proxmox install.
if ! ss -ltn "( sport = :${PORT} )" | grep -q ":${PORT}"; then
    echo "ERROR: nothing listening on :${PORT}" >&2
    systemctl status prometheus-node-exporter --no-pager >&2 || true
    exit 1
fi

echo "==> Smoke-testing /metrics"
curl -fsS "http://localhost:${PORT}/metrics" | head -5

echo ""
echo "==> Done. Next: from docker-host, confirm cross-host reachability:"
echo "    curl -s http://$(hostname -f):${PORT}/metrics | head -5"
