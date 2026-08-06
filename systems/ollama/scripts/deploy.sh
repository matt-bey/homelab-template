#!/usr/bin/env bash
set -euo pipefail

# deploy.sh — Install and configure Ollama as a system service on dev-workstation.
# Safe to re-run — all steps are idempotent.
# Usage:    bash systems/ollama/scripts/deploy.sh [--sync-models]
#   --sync-models  After setup, pull all canonical models via sync-models.sh.
#
# Env overrides (set in ~/.zshrc):
#   HOMELAB_SSH_KEY  SSH private key (default: ~/.ssh/id_ed25519_homelab)
#   HOMELAB_HOST     Hostname or IP  (default: <dev-workstation-hostname>)
#   HOMELAB_USER     SSH username    (default: admin)

SSH_KEY="${HOMELAB_SSH_KEY:-$HOME/.ssh/id_ed25519_homelab}"
HOST="${HOMELAB_HOST:-<dev-workstation-hostname>}"
REMOTE_USER="${HOMELAB_USER:-admin}"
TARGET="${REMOTE_USER}@${HOST}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

SYNC_MODELS=false
[[ "${1:-}" == "--sync-models" ]] && SYNC_MODELS=true

echo "==> Deploying Ollama to ${TARGET}..."

# Upload the deploy script first (stdin = heredoc, no TTY needed), then execute
# it in a second call with -t so sudo can prompt for a password if required.
ssh -i "${SSH_KEY}" "${TARGET}" 'cat > /tmp/ollama-deploy.sh' <<'SCRIPT'
set -euo pipefail

# ── Install ────────────────────────────────────────────────────────────────
if ! command -v ollama &>/dev/null; then
    echo "==> Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
else
    echo "==> Ollama already installed ($(ollama --version 2>/dev/null || echo 'version unknown'))"
fi

# ── Systemd override ────────────────────────────────────────────────────────
OVERRIDE_DIR=/etc/systemd/system/ollama.service.d
OVERRIDE_FILE="${OVERRIDE_DIR}/override.conf"
DESIRED='[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_KEEP_ALIVE=1h"'

sudo mkdir -p "${OVERRIDE_DIR}"

RELOAD=false
if [[ ! -f "${OVERRIDE_FILE}" ]] || [[ "$(cat "${OVERRIDE_FILE}")" != "${DESIRED}" ]]; then
    echo "==> Writing systemd override..."
    printf '%s\n' "${DESIRED}" | sudo tee "${OVERRIDE_FILE}" > /dev/null
    RELOAD=true
fi

# ── Enable service ─────────────────────────────────────────────────────────
if ! systemctl is-enabled --quiet ollama 2>/dev/null; then
    echo "==> Enabling ollama service..."
    sudo systemctl enable ollama
    RELOAD=true
fi

# ── Apply ──────────────────────────────────────────────────────────────────
if $RELOAD; then
    echo "==> Reloading daemon and restarting ollama..."
    sudo systemctl daemon-reload
    sudo systemctl restart ollama
else
    echo "==> Config unchanged — ensuring service is started..."
    sudo systemctl start ollama
fi

# ── Verify ─────────────────────────────────────────────────────────────────
echo ""
systemctl is-active --quiet ollama \
    && echo "==> ollama is running." \
    || echo "==> WARNING: ollama is not active."
ss -tlnp | grep -q 11434 \
    && echo "==> Listening on 0.0.0.0:11434." \
    || echo "==> WARNING: not listening on 11434."
SCRIPT

ssh -t -i "${SSH_KEY}" "${TARGET}" "bash /tmp/ollama-deploy.sh; rm -f /tmp/ollama-deploy.sh"

if $SYNC_MODELS; then
    echo ""
    echo "==> Syncing models on ${TARGET}..."
    ssh -i "${SSH_KEY}" "${TARGET}" bash < "${SCRIPT_DIR}/sync-models.sh"
fi
