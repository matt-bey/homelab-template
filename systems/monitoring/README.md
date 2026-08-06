# Monitoring

Status: Operational

Host: [docker-host](../docker-host/)

Metrics-based observability stack for `docker-host` and its container workloads. Complements [Uptime Kuma](../uptime-kuma/) (uptime and endpoint checks) with resource-level visibility: per-container CPU and memory, host disk and network, UPS battery/load/runtime, and threshold-based alerts routed to [ntfy](../ntfy/).

Stack: Prometheus, Grafana, cAdvisor, node_exporter, nut-exporter (UPS telemetry from [homelab-server](../homelab-server/config/nut/)), Pushgateway (receives the [ota-tv](../ota-tv/) HDHomeRun signal probe's per-station `ss`/`snq`/`seq` sweeps).

