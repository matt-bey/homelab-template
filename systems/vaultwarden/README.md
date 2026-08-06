# Vaultwarden

Status: Planned

Host: [docker-host](../docker-host/)

Self-hosted, Bitwarden-compatible password vault. Holds the structured secrets Apple Passwords handles poorly — credit cards, secure notes, SSH keys (as escrow), identities, software licenses — while Apple Passwords stays the daily driver for logins, passkeys, and TOTP. The point is to own the vault data locally without leaving the polished Bitwarden client ecosystem, keeping a clean exit to KeePass/etc. if Bitwarden's direction ever forces it.

Reachable at `vault.lab.yourdomain.com` over the LAN and via Tailscale when off-network — no public DNS record and no public ingress. The TLS cert is issued through Traefik's Cloudflare DNS-01 challenge, so the host is never exposed to the internet yet passkeys/WebAuthn still work.

Config is complete and ready to deploy; status flips to Operational after the one-time first-run bootstrap (see runbook).

Operations and first-run bootstrap: [runbook.md](runbook.md)
