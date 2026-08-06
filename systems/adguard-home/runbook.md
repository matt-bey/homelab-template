# AdGuard Home — Runbook

## First-time setup

1. Deploy the container:

```bash
DOCKER_CONTEXT=docker-host docker compose -f systems/adguard-home/config/compose.yaml up -d
```

2. Open the setup wizard at `http://<docker-host-ip>:8888` and complete it:
   - Set admin username and password
   - When asked which interface to listen on for DNS: **All interfaces**
   - When asked which port for the admin UI: leave as **3000** (mapped to 8888 externally)

3. Log in and add upstream DNS servers under **Settings → DNS Settings → Upstream DNS**:
   ```
   https://dns10.quad9.net/dns-query
   1.1.1.1
   8.8.8.8
   ```


## Steady-state ops

```bash
# Check status
DOCKER_CONTEXT=docker-host docker compose -f systems/adguard-home/config/compose.yaml ps

# View logs
DOCKER_CONTEXT=docker-host docker compose -f systems/adguard-home/config/compose.yaml logs -f

# Restart
DOCKER_CONTEXT=docker-host docker compose -f systems/adguard-home/config/compose.yaml restart
```

Admin UI: `http://<docker-host-ip>:8888`

## Recovery after a reboot or hardware move (DNS refused, container looks "Up")

Symptom: `lab.yourdomain.com` names don't resolve, but `docker ps` shows `adguard` as
`Up`. The tell is an **empty `PORTS` column** / `docker port adguard` returning nothing,
and `dig @<docker-host-ip> <name>` getting **connection refused** from another LAN host.

Cause: a boot-timing race. If Docker starts the container before the VM's network has
assigned `<docker-host-ip>`, the host-side publish of the specific-IP binding
(`<docker-host-ip>:53`) never gets established. AdGuard's DNS engine still listens on
`0.0.0.0:53` *inside* the container (so it looks healthy), but nothing on the host
forwards `:53` into it. A plain `restart` re-runs the same container and does **not**
re-establish the missing publish — you must recreate it.

Fix — recreate once the `.50` address is present (it will be, by the time you're looking):

```bash
# Break-glass, on docker-host directly (SSH or Proxmox console — no repo needed):
cd /opt/stacks/adguard-home && docker compose -p adguard-home up -d --force-recreate

# Or from the repo (preferred when you have it + the SSH key):
bash systems/adguard-home/scripts/deploy.sh --force
```

Verify from any other LAN host (not a corporate-managed laptop — those filter outbound
`:53`; query from the Proxmox host or a personal device):

```bash
dig @<docker-host-ip> example.com +short    # expect: an answer, forwarded via AdGuard's upstream
docker port adguard                       # expect: 53/tcp + 53/udp -> <docker-host-ip>:53
```

`--force-recreate` is required: a plain `up -d` sees the container as already "Up" and
leaves the broken (port-less) instance in place. The blast radius of this failure mode is
smaller now that the UDM-SE is the primary resolver (see "Failure modes" below), but
AdGuard still needs to be reachable for ad-blocking/DoH/logging to work. See

## Failure modes

If AdGuard Home goes down, the UDM-SE falls back to its secondary upstream DNS
(`1.1.1.1`, Cloudflare) — clients keep resolving normally, including
`*.lab.yourdomain.com` (answered directly by UDM-SE Local DNS Records, never via AdGuard).
The only loss is ad-blocking, DoH, and query logging until AdGuard is back up — recreate
the container per the recovery steps above.
