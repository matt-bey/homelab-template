#!/usr/bin/env bash
# post-install.sh — Proxmox VE 9.x post-install setup
# Run once as root immediately after a fresh install, before any apt upgrades.
# Idempotent — safe to re-run.
set -euo pipefail

ADMIN_USER="${PVE_ADMIN_USER:-admin}"
TIMEZONE="${TIMEZONE:-America/New_York}"

echo "==> Setting timezone to ${TIMEZONE}"
timedatectl set-timezone "${TIMEZONE}"

# --- Repositories ---

echo "==> Removing enterprise subscription repos"
rm -f /etc/apt/sources.list.d/pve-enterprise.list
rm -f /etc/apt/sources.list.d/pve-enterprise.sources
rm -f /etc/apt/sources.list.d/ceph.list
rm -f /etc/apt/sources.list.d/ceph.sources

echo "==> Adding no-subscription repo"
CODENAME="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
cat > /etc/apt/sources.list.d/pve-no-subscription.list <<EOF
deb http://download.proxmox.com/debian/pve ${CODENAME} pve-no-subscription
EOF

echo "==> Updating package lists and upgrading"
apt-get update -q
apt-get full-upgrade -y

# --- SSH hardening ---

echo "==> Hardening SSH"
SSHD_CONF=/etc/ssh/sshd_config

# Disable password auth; keep key-based root login
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "${SSHD_CONF}"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "${SSHD_CONF}"

systemctl reload ssh

# --- Proxmox admin user ---

echo "==> Creating Proxmox admin user: ${ADMIN_USER}@pam"

# Create the Linux system account if it doesn't exist
if ! id "${ADMIN_USER}" &>/dev/null; then
    useradd -m -s /bin/bash "${ADMIN_USER}"
    echo "    Linux account '${ADMIN_USER}' created. Set a password with: passwd ${ADMIN_USER}"
fi

# Create the Proxmox user if it doesn't exist
if ! pveum user list | grep -q "^${ADMIN_USER}@pam"; then
    pveum user add "${ADMIN_USER}@pam"
fi

# Grant PVEAdmin role at the root level
pveum aclmod / -user "${ADMIN_USER}@pam" -role PVEAdmin

echo "    ${ADMIN_USER}@pam has PVEAdmin on /."
echo "    Log into the web UI at https://$(hostname -f):8006 as ${ADMIN_USER}@pam."

# --- Done ---

echo ""
echo "==> Post-install complete. Next steps:"
echo "    1. Set a password for the '${ADMIN_USER}' Linux account: passwd ${ADMIN_USER}"
echo "    2. Verify web UI login as ${ADMIN_USER}@pam at https://$(hostname -f):8006"
echo "    3. Remove this script from the server once setup is confirmed."
