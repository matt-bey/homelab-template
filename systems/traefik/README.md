# Traefik

Status: Operational

Host: [docker-host](../docker-host/)

Reverse proxy for all container workloads on docker-host. Terminates TLS using a Let's Encrypt wildcard cert for `*.lab.yourdomain.com` via Cloudflare DNS-01 challenge. All HTTP traffic redirects to HTTPS.

## Routes

| Hostname                          | Backend          |
| --------------------------------- | ---------------- |
| `traefik.lab.yourdomain.com`         | Traefik dashboard (basic auth) |
| `ntfy.lab.yourdomain.com`            | [ntfy](../ntfy/) |
| `uptime.lab.yourdomain.com`          | [uptime-kuma](../uptime-kuma/) |
| `litellm.lab.yourdomain.com`         | [litellm](../litellm/) |
| `open-webui.lab.yourdomain.com`      | [open-webui](../open-webui/) |
| `adguard.lab.yourdomain.com`         | [adguard-home](../adguard-home/) |
| `proxmox.lab.yourdomain.com`         | [homelab-server](../homelab-server/) Proxmox web UI (external; file provider) |

Container backends are auto-discovered via the Docker provider. External backends (e.g., the Proxmox web UI on the hypervisor itself) are declared via the file provider — see the `traefik_dynamic_proxmox` config block in `config/compose.yaml`.

## Prerequisites

Before first deploy on docker-host:

1. Create the shared proxy network: `docker network create traefik-proxy`
2. Add a DNS rewrite in AdGuard Home: `*.lab.yourdomain.com` → `<docker-host-ip>`
3. Create a Cloudflare API token scoped to `yourdomain.com` — see `config/.env.example`
4. Copy `config/.env.example` to `config/.env` and populate values
