# ntfy

Status: Operational

Host: [docker-host](../docker-host/)

Self-hosted push notification server. Receives HTTP POST requests from other services (primarily Uptime Kuma) and delivers them to the ntfy phone app.

Available at `https://ntfy.lab.yourdomain.com`.

## iOS note

iOS push requires relaying through ntfy.sh as an upstream — the ntfy iOS app uses Apple's push infrastructure, which only works via ntfy.sh-hosted relay. The `upstream-base-url` directive in the inline `ntfy_config` block of `config/compose.yaml` handles this. No ntfy.sh account needed; the relay is anonymous.

## Usage

Post a notification from anywhere on the LAN:

```bash
curl -d "LiteLLM is down" https://ntfy.lab.yourdomain.com/homelab-alerts
```

Subscribe to the `homelab-alerts` topic in the ntfy app using server `https://ntfy.lab.yourdomain.com`.
