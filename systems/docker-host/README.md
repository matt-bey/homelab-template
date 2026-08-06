# Docker Host

Status: Operational

Host: [homelab-server](../homelab-server/)

Ubuntu Server 24.04 LTS VM on Proxmox VE. Runs Docker + Docker Compose and hosts all homelab container workloads. Dual-role: workload of `homelab-server`, host of the container workloads listed below.

## Workloads

- [traefik](../traefik/) — Reverse proxy; terminates TLS for all other workloads
- [ntfy](../ntfy/) — Push notification server for homelab alerts
- [uptime-kuma](../uptime-kuma/) — Uptime monitor; alerts via ntfy
- [litellm](../litellm/) — LLM gateway for Claude Code and other consumers
- [open-webui](../open-webui/) — Chat interface for local models, backed by LiteLLM
- [searxng](../searxng/) — Self-hosted metasearch engine; provides web search to Open WebUI and LiteLLM
- [adguard-home](../adguard-home/) — Internal DNS (temporary, until UniFi)
- [mosquitto](../mosquitto/) — MQTT broker for Pi/Arduino/ESP projects
- [monitoring](../monitoring/) — Metrics stack (Prometheus, Grafana, cAdvisor, node_exporter)
- [n8n](../n8n/) — Workflow automation; alert relay and general homelab automation
- [vaultwarden](../vaultwarden/) — Self-hosted Bitwarden-compatible password vault; Planned
- [backups](../backups/) — Volume-level backup container (C2 layer of the backup system); Planned
- [home-automation](../home-automation/) — Home Assistant control plane + Z-Wave coordinator; Planned

