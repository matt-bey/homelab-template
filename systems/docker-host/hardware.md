# Docker Host — Hardware

Virtual machine on [homelab-server](../homelab-server/) (ACEMAGICIAN AM06Pro, 8c/16t / 32 GB RAM).

| Resource     | Allocation         | Notes                                          |
| ------------ | ------------------ | ---------------------------------------------- |
| vCPU         | 6                  | Leaves 2 cores headroom for Proxmox host       |
| RAM          | 16 GB              | Leaves 16 GB headroom for Proxmox host         |
| Boot disk    | 100 GB virtual     | LVM-thin on host's 348 GB thin pool            |
| Network      | VirtIO NIC on vmbr0 | Bridged; IP via DHCP reservation              |
