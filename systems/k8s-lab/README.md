# k8s-lab

Status: Building

Host: [homelab-server](../homelab-server/)

Single-node [k3s](https://k3s.io/) cluster on a Proxmox VM (VMID 110), stood up as a
dedicated Kubernetes substrate for evaluating k8s-native tooling that doesn't ship any
other way. Dual-role: workload of `homelab-server`, host of the k3s workloads below.

Its first and current reason to exist is [envoy-ai-gateway](../envoy-ai-gateway/) — Envoy
AI Gateway only deploys on Kubernetes, so this cluster is the lab home for that
for why a dedicated cluster (rather than retrofitting `docker-host`) is the right call.

## Workloads

- [envoy-ai-gateway](../envoy-ai-gateway/) — Envoy AI Gateway MCP gateway POC

