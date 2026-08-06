# Vaultwarden — Runbook

Operational procedures for the self-hosted vault. Deploy actions run from a device
with the repo checked out and SSH access to `docker-host` (not from the host itself).

## Deploy

```bash
# From the repo root on the deploy device:
bash systems/vaultwarden/scripts/deploy.sh           # apply changes
bash systems/vaultwarden/scripts/deploy.sh --force   # also pull latest image + recreate
```

The script rsyncs `config/` to `/opt/stacks/vaultwarden` on `docker-host` and runs
`docker compose up -d`. `TARGET` overrides the SSH target (default `admin@docker-host.local`).

Prereqs (one time): `cp config/.env.example config/.env` and fill in `ADMIN_TOKEN`.
`.env` is gitignored and ships to the host via rsync — it never lands in git.

## First-run bootstrap

Vaultwarden has no built-in "first admin" account, so creating yours is a deliberate,
temporary opening of registration:

1. Generate the admin token and write `config/.env`:
   ```bash
   docker run --rm -it vaultwarden/server /vaultwarden hash   # paste the $argon2id$... hash
   ```
2. In `config/.env`, set `SIGNUPS_ALLOWED=true`.
3. Deploy: `bash systems/vaultwarden/scripts/deploy.sh`.
4. Browse to `https://vault.lab.yourdomain.com` (on-LAN or over Tailscale) and register
   your single account with a strong, unique master password. Store that master
   password in Apple Passwords — it is NOT recoverable and must not live only here.
5. Set `SIGNUPS_ALLOWED=false` in `config/.env` and redeploy. Registration is now closed.

## Lock-down checklist (after bootstrap)

- [ ] `SIGNUPS_ALLOWED=false` and `INVITATIONS_ALLOWED=false` (single-user vault).
- [ ] `/admin` reachable only with the `ADMIN_TOKEN`; token stored as an Argon2 hash, not plaintext.
- [ ] No public DNS record for `vault.lab.yourdomain.com`; confirm it resolves only on
      LAN + Tailscale. The box must not be reachable from the public internet.
- [ ] Two-step login enabled on the account (TOTP/passkey) from inside the vault settings.
- [ ] Master password recorded in Apple Passwords (the recovery-safe location).

## Keep the server current — the client-version trap

Bitwarden clients update faster than Vaultwarden. A fresh client can call a new API
endpoint an older server hasn't implemented yet, and the failure is sneaky: **existing
logged-in sessions keep working while only brand-new logins fail**. So a stale phone
session is NOT proof the server is healthy.

- Symptom "a new device/browser can't log in but my phone still works" ⇒ server is too
  old, not a client bug. Fix by pulling the latest image:
  ```bash
  bash systems/vaultwarden/scripts/deploy.sh --force
  ```
- Refresh the image periodically rather than pin-and-forget for a year.

## Backups and restore

Two layers, both inherited from the [backups](../backups/) system — no Vaultwarden-specific
job needed:

- **Weekly volume backup** — `offen/docker-volume-backup` tars the `vaultwarden-data`
  volume to the ZFS `backups` pool (secondary SSD). The `stop-during-backup` label
  quiesces the container so SQLite is captured crash-consistent.
- **Nightly VM snapshot** — Proxmox snapshots the whole `docker-host` VM.

Restore (volume-level):

```bash
# On docker-host, with the stack stopped:
docker compose -p vaultwarden down
# untar the backed-up vaultwarden-data archive back into the named volume, then:
docker compose -p vaultwarden up -d
```

**Disaster-recovery hedge (manual, occasional).** Same-box backups don't cover
theft/fire/ransomware. Every month or two, export an encrypted vault copy from a
Bitwarden client (Account settings → Export vault → **encrypted, password-protected**)
and stash it in iCloud Drive. The export is protected by your master password, so it's
safe to keep off-box. This caps a total-homelab-loss event at "a few weeks of changes"
instead of the whole vault.

## Common tasks

- **Logs:** `ssh admin@docker-host.local 'docker logs --tail=100 vaultwarden'`
- **Restart:** `ssh admin@docker-host.local 'docker restart vaultwarden'`
- **Admin diagnostics:** `https://vault.lab.yourdomain.com/admin` (uses `ADMIN_TOKEN`)
- **Rotate ADMIN_TOKEN:** regenerate the hash, update `config/.env`, redeploy.
