#!/usr/bin/env bash
# setup-heartbeat.sh — Idempotent. Installs the weekly cron that sends a heartbeat
# to Uptime Kuma after a successful backup run. Run on docker-host (called by deploy-docker-volume-backup.sh).
#
# Environment overrides:
#   PUSH_URL        Uptime Kuma push URL  (default: http://uptime-kuma:3001/api/push/6IgWrisquA?status=up&msg=OK&ping=)
#   BACKUP_DIR      Directory to check for fresh backups (default: /mnt/backups)
#   CONTAINER       Backup container name (default: backups-docker-volume-backup-1)
set -euo pipefail

PUSH_URL="${PUSH_URL:-http://uptime-kuma:3001/api/push/6IgWrisquA?status=up&msg=OK&ping=}"
BACKUP_DIR="${BACKUP_DIR:-/mnt/backups}"
CONTAINER="${CONTAINER:-backups-docker-volume-backup-1}"

CRON_MARKER="docker-volume-backup heartbeat"
CRON_LINE="30 4 * * 0 find ${BACKUP_DIR} -name '*.tar.gz' -mtime -1 | grep -q . && docker exec ${CONTAINER} wget -q -O- '${PUSH_URL}' > /dev/null 2>&1 # ${CRON_MARKER}"

if crontab -l 2>/dev/null | grep -qF "${CRON_MARKER}"; then
    echo "==> Heartbeat cron already installed"
else
    echo "==> Installing heartbeat cron"
    (crontab -l 2>/dev/null; echo "${CRON_LINE}") | crontab -
fi

echo "==> Done: heartbeat scheduled for Sundays at 04:30"
