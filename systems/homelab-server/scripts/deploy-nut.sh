#!/usr/bin/env bash
# deploy-nut.sh — Idempotently deploy the NUT UPS config to the Proxmox host.
#
# Pushes systems/homelab-server/config/nut/ to /etc/nut on the host, installs
# NUT if absent, fixes ownership/permissions, and (re)starts the driver + server
# + monitor. Safe to re-run: the repo files are source of truth and overwrite the
# host copies each run.
#
# Secrets (upsd.users, upsmon.conf): follow the repo convention used by litellm's
# .env — the REAL files live locally, gitignored, and are pushed by this deploy.
# Create them from the .example files and set a matching [upsmon] password:
#   cp config/nut/upsd.users.example  config/nut/upsd.users
#   cp config/nut/upsmon.conf.example config/nut/upsmon.conf
# When a local real file exists it wins (it's the source of truth). If none
# exists, the deploy seeds .example on the host once and STOPS. Either way it
# refuses to start services while a CHANGEME placeholder password remains.
#
# Usage:  bash systems/homelab-server/scripts/deploy-nut.sh
# Env:    HOMELAB_HOST  (default <homelab-server-ip>)
#         HOMELAB_USER  (default root — admin@pam has no Linux sudo; /etc/nut and
#                        systemctl need root, so connect as root directly)
#         SUDO          (default empty; set SUDO="sudo" if connecting as a
#                        sudo-capable user instead of root)
#         SSH_KEY       (see scripts/_deploy.sh; default ~/.ssh/id_ed25519_macbook)
#
# Named deploy-nut.sh (not deploy.sh) because homelab-server is a Proxmox host
# with several task scripts (post-install, vm-create, lxc-create), not a single
# deployable — a bare deploy.sh would be ambiguous here.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "${REPO_ROOT}/scripts/_deploy.sh"

HOST="${HOMELAB_HOST:-<homelab-server-ip>}"
USER="${HOMELAB_USER:-root}"
TARGET="${USER}@${HOST}"
SUDO="${SUDO-}"

# 1. Ship the config tree to a staging dir on the host (README/.gitignore ride
#    along harmlessly; the remote step copies only the files it needs into /etc/nut).
rsync_to "${REPO_ROOT}/systems/homelab-server/config/nut/" "${TARGET}:/tmp/nut-config/"

# 2. Install + place + perms + (re)start — idempotently, privileged, on the host.
ssh_exec "${TARGET}" "${SUDO} bash -s" <<'REMOTE'
set -euo pipefail
STAGING=/tmp/nut-config

# Precondition: the UPS must be visible on USB (CyberPower vendor 0764).
if ! lsusb | grep -qiE 'cyber|0764'; then
    echo "ERROR: No CyberPower UPS found on USB (vendor 0764). Check the cable. Aborting." >&2
    exit 1
fi

# Install NUT (and curl, needed by the ntfy alert handler) if not already present.
if ! dpkg -s nut >/dev/null 2>&1; then
    echo "==> Installing NUT"
    apt-get update -q
    apt-get install -y nut
fi
if ! dpkg -s curl >/dev/null 2>&1; then
    echo "==> Installing curl (for ntfy alerts)"
    apt-get update -q
    apt-get install -y curl
fi

mkdir -p /etc/nut/handlers

# No-secret config: repo is source of truth — overwrite on every run.
install -m 640 -o root -g nut  "${STAGING}/nut.conf"              /etc/nut/nut.conf
install -m 640 -o root -g nut  "${STAGING}/ups.conf"              /etc/nut/ups.conf
install -m 640 -o root -g nut  "${STAGING}/upsd.conf"             /etc/nut/upsd.conf
install -m 640 -o root -g nut  "${STAGING}/upssched.conf"         /etc/nut/upssched.conf
install -m 755 -o root -g root "${STAGING}/handlers/upssched-cmd" /etc/nut/handlers/upssched-cmd

# ntfy alert settings: local copy wins (it may carry a token); otherwise seed the
# .example, whose defaults are functional (no auth needed) so alerts work out of
# the box. Not gated — a missing/empty token never blocks startup.
if [ -f "${STAGING}/handlers/ntfy.env" ]; then
    install -m 640 -o root -g nut "${STAGING}/handlers/ntfy.env" /etc/nut/handlers/ntfy.env
elif [ ! -f /etc/nut/handlers/ntfy.env ]; then
    install -m 640 -o root -g nut "${STAGING}/handlers/ntfy.env.example" /etc/nut/handlers/ntfy.env
fi

# Secret files: a LOCAL real copy (rsynced into staging) is the source of truth
# and is pushed each run. If there's no local copy, seed .example on the host once
# and flag it. A host file edited out-of-band with no local copy is left as-is.
created_secret=0
for f in upsd.users upsmon.conf; do
    if [ -f "${STAGING}/${f}" ]; then
        install -m 640 -o root -g nut "${STAGING}/${f}" "/etc/nut/${f}"
    elif [ ! -f "/etc/nut/${f}" ]; then
        install -m 640 -o root -g nut "${STAGING}/${f}.example" "/etc/nut/${f}"
        created_secret=1
    fi
done

# Don't leave secret copies lingering in the shared staging dir.
rm -f "${STAGING}/upsd.users" "${STAGING}/upsmon.conf" "${STAGING}/handlers/ntfy.env"

if [ "${created_secret}" -eq 1 ]; then
    echo ""
    echo "!!  Seeded /etc/nut secret files from .example (no local copies found)."
    echo "!!  Preferred: create real files LOCALLY (gitignored) from the .example"
    echo "!!  files, set a matching [upsmon] password in both, and re-run. Or edit"
    echo "!!  the seeded files directly in /etc/nut on the host."
    echo "!!  Refusing to start services with placeholder passwords."
    exit 0
fi

# Guard: never start with the placeholder password, wherever it was edited.
if grep -qi 'CHANGEME' /etc/nut/upsd.users /etc/nut/upsmon.conf 2>/dev/null; then
    echo ""
    echo "!!  Placeholder 'CHANGEME' password still present in /etc/nut secret files."
    echo "!!  Set real, matching [upsmon] passwords (in upsd.users and upsmon.conf),"
    echo "!!  then re-run. Refusing to start services."
    exit 0
fi

# Ensure the USB device is group-owned by 'nut' so the driver (which drops
# privileges to the 'nut' user) can open it. Required when the UPS was plugged in
# before NUT was installed, so udev never applied the ownership rule on hotplug.
echo "==> Reapplying NUT udev rules to the connected UPS"
udevadm control --reload-rules || true
udevadm trigger --action=add --subsystem-match=usb || true

# Bring up / refresh the stack. The enumerator regenerates the driver unit from
# ups.conf on NUT 2.8; '|| true' tolerates older layouts that lack it.
echo "==> Restarting NUT driver + server + monitor"
systemctl restart nut-driver-enumerator 2>/dev/null || true
systemctl enable --now nut-server nut-monitor
systemctl restart nut-server nut-monitor

# The driver needs a few seconds after restart to init USB and register with
# upsd, so poll rather than checking once (a one-shot check races the driver and
# yields a false "Driver not connected").
echo "==> Waiting for the driver to connect to upsd..."
for _ in $(seq 1 10); do
    upsc cp1500@localhost >/dev/null 2>&1 && break
    sleep 2
done

echo "==> upsc readout:"
upsc cp1500@localhost || {
    echo "upsc failed. Debug (newest first):" >&2
    echo "  systemctl status 'nut-driver@cp1500' nut-server" >&2
    echo "  journalctl -e -u nut-server -u 'nut-driver@cp1500'" >&2
    echo "Do NOT run 'upsdrvctl start' by hand while the services are up — it" >&2
    echo "collides with nut-driver@cp1500 (duplicate-instance error)." >&2
    exit 1
}
echo "==> NUT deploy complete."
REMOTE
