# HDHomeRun signal probe

A small workload that builds a historical record of per-station signal quality
be judged on time-series data (leaf-off vs leaf-on, calm vs windy) instead of
one-off readings. Runs on [docker-host](../../docker-host/); the metrics land
in the [monitoring](../../monitoring/) stack and surface on the **OTA TV —
Signal** Grafana dashboard.

## How it works

The HDHomeRun only reports `ss`/`snq`/`seq` for a tuner that is *currently*
locked to a channel — there is no passive all-stations readout. So the probe
borrows a free tuner, steps it through the watched RF channels (from
status line, releases the tuner, and pushes the numbers to the Prometheus
Pushgateway. Every ~10 minutes by default. If all four tuners are busy (rare —
no DVR today) it skips the sweep and pushes `ota_tv_probe_success=0`.

See the header of `probe.py` for the design rationale: why active sampling, why
the control-protocol CLI over the HTTP API, why address by IP, and the
tuner-etiquette / collision trade-off.

## Metrics

| Metric                   | Meaning                                  |
| ------------------------ | ---------------------------------------- |
| `ota_tv_signal_strength` | `ss` — raw level, 0-100                  |
| `ota_tv_signal_quality`  | `snq` — SNR, 0-100 (the bottleneck)      |
| `ota_tv_symbol_quality`  | `seq` — 0-100 (drops first on artifacts) |
| `ota_tv_locked`          | 1 if the channel locked, else 0          |
| `ota_tv_probe_success`   | 1 if a sweep ran, 0 if all tuners busy   |
| `ota_tv_probe_tuner`     | tuner index used for the last sweep      |

All per-station series carry `station`, `network`, `virtual`, `rf` labels.

## Deploy

Canonical path — idempotent, syncs `config/` to docker-host and rebuilds:

```bash
bash systems/ota-tv/scripts/deploy.sh          # or --force to recreate
```

Local/manual equivalent, run from this directory on docker-host:

```bash
cp .env.example .env        # adjust if the tuner IP ever changes
docker compose -p ota-tv up -d --build
docker logs -f hdhomerun-probe
```

One-shot test sweep without the loop (prints the readings and pushes once):

```bash
docker compose -p ota-tv run --rm hdhomerun-probe python -u probe.py --once
```

Requires the inter-VLAN firewall to permit docker-host -> `<ota-tuner-ip>` on the
HDHomeRun control port (tcp/udp 65001), and the `pushgateway` service in the
monitoring stack to be up.
