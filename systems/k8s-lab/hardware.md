# k8s-lab — Hardware

Virtual machine on [homelab-server](../homelab-server/) (ACEMAGICIAN AM06Pro, 8c/16t / 32 GB RAM).

| Resource  | Allocation          | Notes                                                          |
| --------- | ------------------- | -------------------------------------------------------------- |
| vCPU      | 4                   | Oversubscribed alongside docker-host's 6 (host has 16 threads) |
| RAM       | 8 GB                | Balloon off. Leaves ~5 GB for Proxmox + burst with docker-host's 16 GB |
| Boot disk | 40 GB virtual       | LVM-thin on host's 348 GB thin pool; thin-provisioned          |
| Network   | VirtIO NIC on vmbr0 | Bridged; IP via DHCP reservation                               |

Sized for a single-node k3s control plane plus Envoy Gateway, Envoy AI Gateway,
cert-manager, and a handful of MCP-server pods. If the trace backend (Phase 4b) adds
memory pressure, the first lever is trimming docker-host's headroom, not growing this VM.
