# Uptime Kuma

Status: Operational

Host: [docker-host](../docker-host/)

Uptime monitor for all docker-host services. Checks HTTP endpoints on a schedule and fires alerts to [ntfy](../ntfy/) when something goes down or recovers.

Available at `https://uptime.lab.yourdomain.com`.

## Monitors

Configured via the web UI. Suggested monitors on first setup:

| Name          | Type  | URL / Target                                    |
| ------------- | ----- | ----------------------------------------------- |
| Traefik       | HTTP  | `https://traefik.lab.yourdomain.com`               |
| LiteLLM       | HTTP  | `https://litellm.lab.yourdomain.com/health/liveliness` |
| Open WebUI    | HTTP  | `https://open-webui.lab.yourdomain.com`            |
| AdGuard Home  | HTTP  | `https://adguard.lab.yourdomain.com`               |
| AdGuard DNS   | DNS   | `<docker-host-ip>` port 53                         |
| Ollama        | HTTP  | `http://<dev-workstation-ip>:11434/api/tags` (dev-workstation)         |

## Notifications

Add an ntfy notification channel in the UI:

- URL: `https://ntfy.lab.yourdomain.com`
- Topic: `homelab-alerts`
