#!/usr/bin/env bash
# Run on net-gateway LXC. Installs Tailscale and configures it as the subnet
# router for the Core/Clients/IoT VLANs and the Management network
# (<management-subnet> — the UDM-SE controller; cloud Remote Access is off so
# Tailscale is the only remote admin path). Idempotent — safe to run again.
#
# Prerequisites: net-gateway must have TUN device access configured in Proxmox.
# See ../config/lxc-tun.conf before running this.
set -euo pipefail

SUBNETS="${TAILSCALE_SUBNETS:-<core-subnet>,<clients-subnet>,<iot-subnet>,<management-subnet>}"

# Install Tailscale if not already present
if ! command -v tailscale &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
fi

# Enable IP forwarding — required for subnet routing
SYSCTL_CONF="/etc/sysctl.d/99-tailscale.conf"
if [[ ! -f "$SYSCTL_CONF" ]]; then
  cat <<EOF | sudo tee "$SYSCTL_CONF"
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1
EOF
  sudo sysctl -p "$SYSCTL_CONF"
fi

# Bring up Tailscale as subnet router
# --accept-dns=false: don't let Tailscale override system DNS on this server
# Approve the advertised route in the admin panel after running this
sudo tailscale up \
  --advertise-routes="$SUBNETS" \
  --accept-dns=false

echo ""
echo "Next steps in the Tailscale admin panel:"
echo "  1. Approve subnet routes $SUBNETS from net-gateway"
echo "  2. Disable key expiry for net-gateway"
echo "  3. Set global nameserver to <docker-host-ip> (AdGuard Home)"
