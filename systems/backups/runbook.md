# Backups — Runbook

## Schedules

| Layer | Tool | Schedule | Retention | Target |
|---|---|---|---|---|
| VM snapshots | vzdump | Daily 02:00 | 7 daily / 4 weekly | `backup-vzdump` (homelab-server) |
| Container volumes | docker-volume-backup | Sundays 03:00 | 56 days (8 weeks) | `/backups/c2volumes` (homelab-server via NFS) |

## Where backups live

On homelab-server:

- VM snapshots: `/backups/vzdump/` (ZFS dataset `backups/vzdump`)
- Container volumes: `/backups/c2volumes/` (ZFS dataset `backups/c2volumes`, NFS-exported to docker-host at `/mnt/backups`)

## Check backup health

**VM snapshots** — Proxmox UI: homelab-server → backup-vzdump → Content. Should show one `.vma.zst` per VM per day.

**Container volumes** — on homelab-server:

```bash
ls -lh /backups/c2volumes/
```

## Test the Uptime Kuma heartbeat manually

Run on docker-host — only fires if a backup less than 1 day old exists:

```bash
find /mnt/backups -name "*.tar.gz" -mtime -1 | grep -q . && docker exec docker-volume-backup wget -q -O- "http://uptime-kuma:3001/api/push/6IgWrisquA?status=up&msg=OK&ping="
```

Should return `{"ok":true}` and flip the Uptime Kuma monitor green. The cron runs this automatically every Sunday at 04:30 via docker-host's crontab.

## Trigger a manual container volume backup

```bash
ssh admin@docker-host.local "docker exec docker-volume-backup backup"
```

## Restore a container volume (side-by-side, non-destructive)

Replace `<volume>` with the volume short name (e.g. `uptime-kuma-data`) and `<backup-file>` with the filename from `/backups/c2volumes/`.

```bash
# 1. Create a restore volume
docker volume create <volume>-restore-test

# 2. Extract from the backup
docker run --rm \
  -v /mnt/backups/<backup-file>:/backup.tar.gz:ro \
  -v <volume>-restore-test:/restore \
  busybox \
  tar -xzf /backup.tar.gz -C /restore --strip-components=2 backup/<volume>/

# 3. Spin up a test instance (adjust image and port per workload)
docker run -d \
  --name <workload>-restore-test \
  -p <free-port>:<service-port> \
  -v <volume>-restore-test:/app/data \
  <image>

# 4. Verify, then tear down
docker stop <workload>-restore-test
docker rm <workload>-restore-test
docker volume rm <volume>-restore-test
```

## Restore a VM snapshot

Proxmox UI: homelab-server → backup-vzdump → Content → select backup → Restore. Use a new VMID to restore side-by-side without touching the running VM.

## ZFS scrub (verify backup disk integrity)

Run periodically on homelab-server to catch silent corruption:

```bash
zpool scrub backups
zpool status backups
```

## NFS mount lost on docker-host

If `/mnt/backups` is not mounted on docker-host:

```bash
sudo mount /mnt/backups
```

If that fails, re-run the NFS setup from the repo root on the MacBook:

```bash
bash systems/backups/scripts/deploy-vm-nfs.sh
```
