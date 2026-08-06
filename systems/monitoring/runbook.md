# Monitoring — Runbook

Operational guide for the monitoring stack (Prometheus + Grafana + cAdvisor + node-exporter on `docker-host`, plus bare-metal `prometheus-node-exporter` on `homelab-server`).

## Quick reference

| What           | Where                                    |
| -------------- | ---------------------------------------- |
| Grafana UI     | `https://grafana.lab.yourdomain.com`        |
| Prometheus UI  | `https://prometheus.lab.yourdomain.com` (basic auth — same creds as Traefik dashboard) |
| Alert relay    | n8n → ntfy (`homelab-monitoring` topic)  |
| Compose stack  | `systems/monitoring/config/compose.yaml` |
| Scrape config  | `systems/monitoring/config/prometheus.yml` |
| Bare-metal exporter scripts | `systems/monitoring/scripts/` |

Deploy commands run from the personal MacBook or dev-workstation (the work MacBook lacks the homelab SSH key):

```bash
bash systems/monitoring/scripts/deploy.sh
```

## First-time deploy

Pre-flight on the deploy machine:

- SSH access to `admin@<homelab-server-ip>` (Proxmox host) and `admin@docker-host.local` works without prompts.
- `.env` files created from the `.env.example` siblings — see "Secrets" below.

### 1. Apply Traefik metrics endpoint

The Traefik compose now declares a `metrics` entryPoint on `:8082` and a `metrics.prometheus` block. Recreate Traefik to pick this up. Brief (<1s) ingress blip while Traefik restarts; routed workloads stay connected to `traefik-proxy` and rebind automatically.

```bash
bash systems/traefik/scripts/deploy.sh
```

Verify the metrics endpoint is alive from inside docker-host (the host port is intentionally not published):

```bash
ssh admin@docker-host.local \
    'docker run --rm --network traefik-proxy curlimages/curl:latest \
     -s http://traefik:8082/metrics | head -5'
```

### 2. Install bare-metal node-exporter on the Proxmox host

```bash
scp systems/monitoring/scripts/install-node-exporter.sh \
    systems/monitoring/scripts/install-lvm-textfile-collector.sh \
    systems/monitoring/scripts/lvm-textfile.sh \
    admin@<homelab-server-ip>:/tmp/

ssh root@<homelab-server-ip> 'bash /tmp/install-node-exporter.sh'
ssh root@<homelab-server-ip> 'bash /tmp/install-lvm-textfile-collector.sh'
```

Confirm cross-host reachability from inside docker-host (Prometheus will scrape from there).
`.local` mDNS does not resolve from docker-host — use the LAN IP directly (already set in `prometheus.yml`):

```bash
ssh admin@docker-host.local \
    'curl -s http://<homelab-server-ip>:9100/metrics | head -3'
```

### 3. Install exporters on dev-workstation

Run as root on dev-workstation (`ssh admin@<dev-workstation-ip>`, then `sudo -i`):

```bash
# node_exporter — same pattern as homelab-server
scp systems/monitoring/scripts/install-node-exporter.sh admin@<dev-workstation-ip>:/tmp/
ssh root@<dev-workstation-ip> 'bash /tmp/install-node-exporter.sh'

# nvidia_gpu_exporter — wraps nvidia-smi, listens on :9835
scp systems/monitoring/scripts/install-nvidia-gpu-exporter.sh admin@<dev-workstation-ip>:/tmp/
ssh root@<dev-workstation-ip> 'bash /tmp/install-nvidia-gpu-exporter.sh'
```

Confirm reachability from docker-host (where Prometheus runs):

```bash
ssh admin@docker-host.local 'curl -s http://<dev-workstation-ip>:9100/metrics | head -3'
ssh admin@docker-host.local 'curl -s http://<dev-workstation-ip>:9835/metrics | grep nvidia_smi | head -3'
```

### 4. Bring up the monitoring stack

```bash
bash systems/monitoring/scripts/deploy.sh
```

Verify all scrape targets are UP at `https://prometheus.lab.yourdomain.com/targets` (basic auth — same creds as Traefik dashboard). Or query the API directly:

```bash
ssh admin@docker-host.local \
    'docker exec prometheus wget -qO- http://localhost:9090/api/v1/targets' \
  | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}'
```

Expected jobs (the `n8n` job will read DOWN until step 5 brings n8n up; `node-exporter-dev-workstation` and `nvidia-gpu` will read DOWN until step 3 is done):

- `prometheus` (self)
- `cadvisor`
- `node-exporter-vm`
- `node-exporter-host`
- `traefik`
- `n8n`
- `node-exporter-dev-workstation`
- `nvidia-gpu`

Then verify Grafana renders the three provisioned dashboards at `https://grafana.lab.yourdomain.com`:

- Node Exporter Full
- Docker cAdvisor
- Traefik

### 5. Bring up n8n

```bash
bash systems/n8n/scripts/deploy.sh
```

Open `https://n8n.lab.yourdomain.com`, create the owner account on first login.

### 6. Import + activate the Grafana → ntfy workflow

```bash
ssh admin@docker-host.local \
    'docker exec n8n n8n import:workflow --input=/workflows/grafana-to-ntfy.json'
```

Then in the UI, open the imported workflow and toggle it **active**. (n8n's CLI can import but does not activate.) The webhook is reachable at `http://n8n:5678/webhook/grafana` only after activation.

### 7. End-to-end alert test

In Grafana → Alerting → Contact points → `n8n-relay` → "Test". You should see:

1. Grafana logs a successful webhook POST.
2. n8n's execution log shows the workflow ran.
3. An ntfy notification arrives on the `homelab-monitoring` topic.

To exercise a real alert rule, manually consume RAM on docker-host (e.g., `stress-ng --vm 1 --vm-bytes 1G --timeout 600s`) and wait for the "Memory pressure" rule to fire — `for: 5m`, so be patient.

## Secrets

`.env` files live under each system's `config/`. Both are gitignored. Create from the `.env.example` siblings before first deploy.

- `systems/monitoring/config/.env` — Grafana admin user/password. Change `GF_SECURITY_ADMIN_PASSWORD` from `changeme` before first start.
- `systems/n8n/config/.env` — N8N_ENCRYPTION_KEY. Generate with `openssl rand -hex 32`. Do not rotate after first start (would brick stored credentials).

## Common operations

### Reload Prometheus scrape config after editing prometheus.yml

The compose enables `--web.enable-lifecycle`, so:

```bash
ssh admin@docker-host.local \
    'docker exec prometheus wget -qO- --post-data="" http://localhost:9090/-/reload'
```

No container restart needed.

### Reload Grafana provisioning after editing YAML

Provisioning is re-read on container restart. Datasources and dashboards reload automatically on the `updateIntervalSeconds: 30` cycle. Alert rules require a container restart:

```bash
ssh admin@docker-host.local 'cd /opt/stacks/monitoring && docker compose -p monitoring restart grafana'
```

### Tail logs

```bash
ssh admin@docker-host.local 'cd /opt/stacks/monitoring && docker compose -p monitoring logs -f --tail=100'
```

## Break-glass

### "All alerts stopped firing"

Common chain: n8n is down → Grafana webhook returns non-2xx → alert delivery fails silently.

1. Check Uptime Kuma — there's a separate HTTP monitor on `https://n8n.lab.yourdomain.com` that pings ntfy independently. If that's red, n8n is the problem.
2. `docker compose -p n8n ... ps`, then `... logs n8n`.
3. Restart n8n: `docker compose -p n8n ... restart`.

### "Prometheus targets DOWN"

For an in-VM target (cadvisor, node-exporter, traefik), check the container is up and on `traefik-proxy`.

For `node-exporter-host`, SSH to the Proxmox host and `systemctl status prometheus-node-exporter`. The LVM textfile collector runs on a separate timer: `systemctl status lvm-textfile.timer`.

### "Grafana dashboards empty"

Datasource UID mismatch is the usual cause when JSON is hand-edited. Provisioned datasources have a stable UID of `prometheus`. Dashboards reference that UID; if a dashboard JSON drifts, it'll render empty panels.
