#!/usr/bin/env bash
# install-lvm-textfile-collector.sh — install the LVM thin-pool textfile collector
# alongside prometheus-node-exporter on a Debian/Proxmox host.
#
# Depends on prometheus-node-exporter already being installed (see install-node-exporter.sh).
# Run as root on homelab-server. Idempotent — safe to re-run.
#
# What this does:
#   1. Installs lvm-textfile.sh to /usr/local/sbin/
#   2. Creates a systemd .service unit that runs the script once
#   3. Creates a systemd .timer unit that fires the service every 60 seconds
#   4. Enables and starts the timer
#
# The script writes to /var/lib/prometheus/node-exporter/lvm.prom, which the Debian
# package's default --collector.textfile.directory picks up on each scrape.
set -euo pipefail

# Resolve the directory this install script lives in, so we can find its sibling
# lvm-textfile.sh regardless of where it's invoked from.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${SCRIPT_DIR}/lvm-textfile.sh"
DEST="/usr/local/sbin/lvm-textfile.sh"
TEXTFILE_DIR="/var/lib/prometheus/node-exporter"

echo "==> Verifying source script exists: ${SRC}"
test -f "${SRC}" || { echo "ERROR: missing ${SRC}" >&2; exit 1; }

echo "==> Verifying node-exporter textfile directory: ${TEXTFILE_DIR}"
if [[ ! -d "${TEXTFILE_DIR}" ]]; then
    echo "ERROR: ${TEXTFILE_DIR} not found." >&2
    echo "  Has install-node-exporter.sh been run first?" >&2
    exit 1
fi

echo "==> Installing ${DEST}"
install -m 0755 "${SRC}" "${DEST}"

echo "==> Writing /etc/systemd/system/lvm-textfile.service"
cat > /etc/systemd/system/lvm-textfile.service <<EOF
[Unit]
Description=Emit LVM thin-pool metrics for node-exporter textfile collector
Documentation=https://github.com/prometheus/node_exporter#textfile-collector

[Service]
Type=oneshot
ExecStart=${DEST} ${TEXTFILE_DIR}/lvm.prom
# Run as root because lvs requires elevated privileges to read VG metadata.
User=root
EOF

echo "==> Writing /etc/systemd/system/lvm-textfile.timer"
cat > /etc/systemd/system/lvm-textfile.timer <<EOF
[Unit]
Description=Run LVM thin-pool metric collector every minute

[Timer]
OnBootSec=30s
OnUnitActiveSec=60s
AccuracySec=5s
Unit=lvm-textfile.service

[Install]
WantedBy=timers.target
EOF

echo "==> Reloading systemd and enabling timer"
systemctl daemon-reload
systemctl enable --now lvm-textfile.timer

echo "==> Running the collector once now"
systemctl start lvm-textfile.service

echo "==> Verifying output file"
if [[ ! -s "${TEXTFILE_DIR}/lvm.prom" ]]; then
    echo "ERROR: ${TEXTFILE_DIR}/lvm.prom is empty or missing." >&2
    journalctl -u lvm-textfile.service --no-pager -n 20 >&2 || true
    exit 1
fi

echo ""
echo "==> Done. Sample of emitted metrics:"
grep -E '^node_lvm_thin_pool' "${TEXTFILE_DIR}/lvm.prom" | head -5
echo ""
echo "    Next scrape will surface these as node_lvm_thin_pool_* in Prometheus."
