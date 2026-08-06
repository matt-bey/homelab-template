# Backups

Status: Operational

Backup orchestration for the homelab. Two complementary layers:

- **VM snapshots** — Proxmox snapshots the entire `docker-host` VM and `net-gateway` LXC daily at 02:00. Captures every named volume, container, and config in one image. Restore = one-click through Proxmox UI.
- **Container volume backups** — `offen/docker-volume-backup` on `docker-host` tars each named volume weekly (Sundays 03:00). Granular restore without rolling back the whole VM.

Both target a 250 GB SATA SSD in `homelab-server` formatted as ZFS pool `backups` with `lz4` compression.

Implementation lives on the host that owns each layer:

- VM snapshots — Proxmox backup job configured on [homelab-server](../homelab-server/)
- Container volume backups — `docker-volume-backup` container configured on [docker-host](../docker-host/)

