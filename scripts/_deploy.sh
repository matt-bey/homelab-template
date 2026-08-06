#!/usr/bin/env bash
# _deploy.sh — Shared deploy helpers. Source from per-system deploy scripts.
# Do not invoke directly.
#
# Provides: rsync_to, ssh_exec
# Reads:    SSH_KEY (default: ~/.ssh/id_ed25519_homelab)

SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_macbook}"

# rsync_to SOURCE DST
#   SOURCE: local path (trailing slash = contents only)
#   DST:    user@host:/remote/path
rsync_to() {
    local src="$1" dst="$2"
    local target="${dst%%:*}"
    local path="${dst#*:}"
    echo "==> Syncing ${src} → ${dst}"
    ssh -i "${SSH_KEY}" "${target}" "mkdir -p ${path}"
    rsync -az --delete -e "ssh -i ${SSH_KEY}" "${src}" "${dst}"
}

# ssh_exec TARGET COMMAND...
ssh_exec() {
    local target="$1"; shift
    echo "==> ${target}: $*"
    ssh -i "${SSH_KEY}" "${target}" "$@"
}
