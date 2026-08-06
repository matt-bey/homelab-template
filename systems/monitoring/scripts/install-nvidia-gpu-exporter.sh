#!/usr/bin/env bash
# install-nvidia-gpu-exporter.sh — install nvidia_gpu_exporter on Ubuntu (amd64).
# Run as root on dev-workstation. Idempotent — safe to re-run.
#
# Installs utkuozdemir/nvidia_gpu_exporter, which wraps nvidia-smi to expose
# GPU utilization, VRAM usage, temperature, power draw, and clocks on :9835/metrics.
set -euo pipefail

VERSION="${NVIDIA_GPU_EXPORTER_VERSION:-1.4.1}"
PORT="${NVIDIA_GPU_EXPORTER_PORT:-9835}"

DEB="nvidia-gpu-exporter_${VERSION}_linux_amd64.deb"
DOWNLOAD_URL="https://github.com/utkuozdemir/nvidia_gpu_exporter/releases/download/v${VERSION}/${DEB}"

echo "==> Checking nvidia-smi is available"
if ! command -v nvidia-smi &>/dev/null; then
    echo "ERROR: nvidia-smi not found — install NVIDIA drivers first" >&2
    exit 1
fi
nvidia-smi --query-gpu=name --format=csv,noheader

echo "==> Downloading nvidia_gpu_exporter v${VERSION}"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL "$DOWNLOAD_URL" -o "$TMP/$DEB"

echo "==> Installing .deb"
dpkg -i "$TMP/$DEB"

echo "==> Granting nvidia_gpu_exporter user access to /dev/nvidia* (video group)"
usermod -aG video nvidia_gpu_exporter

echo "==> Enabling and starting nvidia_gpu_exporter"
systemctl enable --now nvidia_gpu_exporter

echo "==> Verifying listener on :${PORT}"
sleep 2
if ! ss -ltn "( sport = :${PORT} )" | grep -q ":${PORT}"; then
    echo "ERROR: nothing listening on :${PORT}" >&2
    systemctl status nvidia_gpu_exporter --no-pager >&2 || true
    exit 1
fi

echo "==> Smoke-testing /metrics"
curl -fsS "http://localhost:${PORT}/metrics" | grep 'nvidia_smi_driver_info' | head -3

echo ""
echo "==> Done. Confirm cross-host reachability from docker-host (where Prometheus runs):"
echo "    curl -s http://<dev-workstation-ip>:${PORT}/metrics | grep nvidia_smi | head -5"
