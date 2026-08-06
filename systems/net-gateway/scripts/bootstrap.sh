#!/usr/bin/env bash
# bootstrap.sh — Baseline setup for the net-gateway LXC.
# Run as root on net-gateway after first boot, before any workload scripts.
# Idempotent — safe to re-run.
#
# Usage (from dev-workstation or MacBook):
#   scp systems/net-gateway/scripts/bootstrap.sh root@net-gateway.lab.yourdomain.com:~
#   ssh root@net-gateway.lab.yourdomain.com bash bootstrap.sh
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

TIMEZONE="${TIMEZONE:-America/New_York}"

echo "==> Setting timezone to ${TIMEZONE}"
timedatectl set-timezone "${TIMEZONE}"

echo "==> Updating package lists"
apt-get update -q

echo "==> Upgrading installed packages"
apt-get upgrade -y -o Dpkg::Options::="--force-confold"

echo "==> Installing base packages"
apt-get install -y \
    ca-certificates \
    curl

echo "==> Hardening SSH"
SSHD_CONF=/etc/ssh/sshd_config
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "${SSHD_CONF}"
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin prohibit-password/' "${SSHD_CONF}"
systemctl reload ssh

echo ""
echo "==> Bootstrap complete. Next: run systems/tailscale/scripts/setup-subnet-router.sh"
