# Tailscale

Status: Operational

Host: [net-gateway](../net-gateway/)

Mesh networking overlay spanning all homelab machines and personal devices. Provides secure remote access without opening ports on the home router.

net-gateway acts as the subnet router, advertising the Core (`<core-subnet>`), Clients (`<clients-subnet>`), IoT (`<iot-subnet>`), and Management (`<management-subnet>`) VLANs to the tailnet. The Management route covers the UDM-SE controller UI — Ubiquiti cloud Remote Access is off, so Tailscale is the only remote admin path. Any device on the tailnet can reach any LAN device — not just Tailscale-enrolled ones. Includes access to all `lab.yourdomain.com` services via AdGuard Home DNS.

## Enrolled machines

| Machine         | Role          | LAN IP        | Tailscale IP |
| --------------- | ------------- | ------------- | ------------ |
| net-gateway           | Subnet router | <net-gateway-ip> | <tailscale-subnet-router-ip>  |
| dev-workstation       | Backup node   | <dev-workstation-ip> | TODO            |
| <admin-laptop>       | Client        | —             | <tailscale-laptop-ip>   |
| <admin-phone>         | Client        | —             | <tailscale-phone-ip>   |
| <admin-tablet> | Client        | —             | <tailscale-tablet-ip> |

Key expiry is disabled on net-gateway and dev-workstation so they don't silently drop off the tailnet. <admin-laptop> and <admin-phone> keep the default 180-day expiry.

## DNS

Split DNS in the Tailscale admin panel routes `lab.yourdomain.com` queries to the UDM-SE Core gateway (`<core-gateway-ip>`). The UDM-SE answers `*.lab.yourdomain.com` directly from its Local DNS Records — AdGuard (`<docker-host-ip>`) has no knowledge of these records and must not be used as the split DNS resolver for this domain. All other queries use each client's local resolver.

## Remote access

Once connected to the tailnet:

- SSH to any enrolled machine by Tailscale IP or MagicDNS hostname
- All `lab.yourdomain.com` services accessible as normal
- Any LAN device reachable via subnet routing (router UI, Proxmox, etc.)
