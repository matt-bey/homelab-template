# net-gateway

Status: Operational

Host: [homelab-server](../homelab-server/)

Lightweight LXC container on Proxmox dedicated to network-level infrastructure. Deliberately separate from docker-host so networking concerns survive a workload VM rebuild.

## Workloads

- [tailscale](../tailscale/) — Mesh networking and subnet routing for remote LAN access

## Provisioning

```bash
bash systems/homelab-server/scripts/lxc-create.sh systems/net-gateway/config/lxc.conf
```

Runs as an unprivileged LXC container. The creation script automatically appends `config/lxc-tun.conf` to the Proxmox container config — this grants access to the kernel TUN device required by Tailscale.
