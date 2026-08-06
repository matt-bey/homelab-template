#!/usr/bin/env bash
# Run on homelab-server or dev-workstation. Installs Tailscale as a plain node
# (no subnet routing). Idempotent — safe to run again.
set -euo pipefail

# Install Tailscale if not already present
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# --accept-dns=false: don't let Tailscale override system DNS on this server
# --accept-routes=true: pick up the subnet route advertised by net-gateway
sudo tailscale up \
  --accept-dns=false \
  --accept-routes=true

echo ""
echo "Next step in the Tailscale admin panel:"
echo "  Disable key expiry for this machine if it is a server."
