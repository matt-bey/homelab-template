# Homelab Server

Status: Operational


## Workloads

- [docker-host](../docker-host/) (VMID 100) — Ubuntu Server 24.04 LTS VM running Docker + Docker Compose; host for all container workloads. [monitoring](../monitoring/) scrapes `prometheus-node-exporter` on this host at `<docker-host-ip>:9100`
- [net-gateway](../net-gateway/) (VMID 200) — Lightweight LXC for network infrastructure; hosts Tailscale subnet router
- [backups](../backups/) — Proxmox VM-level backup orchestration (C1 layer); Planned

