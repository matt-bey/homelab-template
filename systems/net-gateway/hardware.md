# net-gateway — Hardware

Proxmox LXC container on [homelab-server](../homelab-server/).

| Resource | Allocation                          |
| -------- | ----------------------------------- |
| vCPU     | 1                                   |
| RAM      | 256 MB                              |
| Disk     | 4 GB                                |
| Network  | 1 veth NIC on vmbr0 (LAN bridge)    |
| Type     | Unprivileged LXC + TUN passthrough  |
