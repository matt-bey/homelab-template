#!/usr/bin/env bash
# lxc-create.sh — Create a Proxmox LXC container from an lxc.conf spec file.
# Usage (run from repo root on dev-workstation):
#   bash systems/homelab-server/scripts/lxc-create.sh <path/to/lxc.conf>
#
# If an lxc-tun.conf exists alongside the spec file it is automatically
# appended to the Proxmox container config (required for Tailscale).
#
# Environment overrides:
#   PROXMOX_HOST     SSH target for the Proxmox host    (default: root@<homelab-server-ip>)
#   SSH_KEY_TINKER   Path to dev-workstation public key  (default: ~/.ssh/id_ed25519_homelab.pub)
#   SSH_KEY_MACBOOK  Path to MacBook public key          (default: ~/.ssh/id_ed25519_macbook.pub)
#   CT_BRIDGE        Proxmox bridge name                 (default: vmbr0)
#   PROXMOX_STORAGE  Proxmox storage pool                (default: local-lvm)
set -euo pipefail

SPEC_FILE="${1:?Usage: lxc-create.sh <path/to/lxc.conf>}"
SPEC_DIR="$(cd "$(dirname "${SPEC_FILE}")" && pwd)"
TUN_CONF="${SPEC_DIR}/lxc-tun.conf"

PROXMOX_HOST="${PROXMOX_HOST:-root@<homelab-server-ip>}"
SSH_KEY_TINKER="${SSH_KEY_TINKER:-${HOME}/.ssh/id_ed25519_homelab.pub}"
SSH_KEY_MACBOOK="${SSH_KEY_MACBOOK:-${HOME}/.ssh/id_ed25519_macbook.pub}"
CT_BRIDGE="${CT_BRIDGE:-vmbr0}"
PROXMOX_STORAGE="${PROXMOX_STORAGE:-local-lvm}"

# --- Load spec ---

[ -f "${SPEC_FILE}" ] || { echo "lxc.conf not found: ${SPEC_FILE}"; exit 1; }
# shellcheck source=/dev/null
source "${SPEC_FILE}"

for var in CT_ID CT_NAME CT_CORES CT_MEMORY CT_SWAP CT_DISK CT_TEMPLATE; do
    [ -n "${!var:-}" ] || { echo "lxc.conf missing required field: ${var}"; exit 1; }
done

remote() { ssh "${PROXMOX_HOST}" "$@"; }

# --- Prerequisites ---

echo "==> Checking prerequisites"
[ -f "${SSH_KEY_TINKER}" ]  || { echo "SSH key not found: ${SSH_KEY_TINKER}"; exit 1; }
[ -f "${SSH_KEY_MACBOOK}" ] || { echo "SSH key not found: ${SSH_KEY_MACBOOK}"; exit 1; }

# --- LXC template ---

echo "==> Updating template list"
remote "pveam update"

if remote "pveam list local | grep -q '${CT_TEMPLATE}'"; then
    echo "==> Template already present: ${CT_TEMPLATE}"
else
    echo "==> Downloading template: ${CT_TEMPLATE}"
    remote "pveam download local ${CT_TEMPLATE}"
fi

# --- SSH keys ---

echo "==> Uploading SSH keys"
cat "${SSH_KEY_TINKER}" "${SSH_KEY_MACBOOK}" | remote "cat > /tmp/ct-ssh-keys"

# --- Container creation ---

if remote "pct status ${CT_ID}" &>/dev/null; then
    echo "==> Container ${CT_ID} already exists — skipping creation"
else
    echo "==> Creating LXC container ${CT_ID} (${CT_NAME})"
    remote "pct create ${CT_ID} local:vztmpl/${CT_TEMPLATE} \
        --hostname ${CT_NAME} \
        --cores ${CT_CORES} \
        --memory ${CT_MEMORY} \
        --swap ${CT_SWAP} \
        --rootfs ${PROXMOX_STORAGE}:${CT_DISK} \
        --net0 name=eth0,bridge=${CT_BRIDGE},ip=dhcp \
        --unprivileged 1 \
        --onboot 1 \
        --ssh-public-keys /tmp/ct-ssh-keys"

    remote "rm -f /tmp/ct-ssh-keys"

    # Append extra LXC config if present alongside the spec
    if [[ -f "${TUN_CONF}" ]]; then
        echo "==> Appending TUN device config from lxc-tun.conf"
        remote "cat >> /etc/pve/lxc/${CT_ID}.conf" < "${TUN_CONF}"
    fi
fi

echo ""
echo "==> Done. Get the container's MAC address before starting:"
echo "    ssh ${PROXMOX_HOST} \"pct config ${CT_ID} | grep net0\""
echo ""
echo "    Set a DHCP reservation in Google Wifi for that MAC, then start:"
echo "    ssh ${PROXMOX_HOST} pct start ${CT_ID}"
echo ""
echo "    Watch first-boot:"
echo "    ssh ${PROXMOX_HOST} pct console ${CT_ID}"
echo ""
echo "    Confirm the assigned IP:"
echo "    ssh ${PROXMOX_HOST} \"pct exec ${CT_ID} -- ip addr show eth0\""
echo ""
echo "    Then update systems/${CT_NAME}/deployment.md with the IP and MAC."
