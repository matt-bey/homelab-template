# Docker Host — Runbook

## Deploying a workload

Each workload has an idempotent deploy script. Run from the repo root:

```bash
bash systems/<workload>/scripts/deploy.sh           # sync + apply
bash systems/<workload>/scripts/deploy.sh --force   # force-recreate containers
```

The script rsyncs `systems/<workload>/config/` to `/opt/stacks/<workload>/` on docker-host,
then SSHs to run `docker compose -p <workload> up -d --remove-orphans`.

Override the target if needed: `TARGET=admin@<docker-host-ip> bash systems/<workload>/scripts/deploy.sh`

## Checking what's running

```bash
ssh admin@docker-host.local docker ps
ssh admin@docker-host.local 'cd /opt/stacks/<workload> && docker compose -p <workload> ps'
ssh admin@docker-host.local 'cd /opt/stacks/<workload> && docker compose -p <workload> logs -f'
```

## Optional: Docker context for ad-hoc inspection

`setup-context.sh` registers a `docker-host` Docker context. Useful for ad-hoc
inspection without typing the full SSH command each time:

```bash
bash systems/docker-host/scripts/setup-context.sh   # once per machine, idempotent
DOCKER_CONTEXT=docker-host docker ps
```

Do not use the Docker context for deployments — it cannot reliably resolve local
file references (`env_file:`, `configs: file:`, bind-mount volumes).

## Connecting to the VM (break-glass)

```bash
ssh admin@docker-host.local
```

Sudo is passwordless. Docker commands work without sudo (`admin` is in the `docker` group).

## Rebooting

```bash
ssh admin@docker-host.local sudo reboot
```

## Runbook entries for specific workloads

See each workload's own `runbook.md` for workload-specific procedures.
