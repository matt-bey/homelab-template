# ADR 001 — Workload Deployment Mechanism

**Status:** Accepted
**Date proposed:** 2026-05-21
**Date accepted:** 2026-05-21

## Context

All homelab container workloads run on `docker-host`, a VM on `homelab-server`. The repo holds the source of truth: `systems/<workload>/config/` contains compose stacks, configs, and `.env` files. The goal is to apply changes from a workstation without storing the repo on docker-host.

The first approach used Docker Compose's remote context (`DOCKER_CONTEXT=docker-host docker compose -f systems/<workload>/config/compose.yaml up -d`). This has a fundamental limitation: the Docker client forwards `volumes:` bind-mount paths as path strings; the remote daemon resolves them against its own filesystem. Any workload whose compose file references local files — `env_file:`, `configs: file:`, bind-mounted config directories — silently mounts empty or missing paths. The root cause is that Docker remote contexts were designed for Docker Desktop (shared filesystem), not as a general control-plane mechanism.

The same rsync + SSH pattern extends naturally to non-compose systems (LXC containers, bare-metal scripts) that are managed over SSH.

## Goals

- Source of truth for all workload config lives in the repo, not on target hosts.
- Deployments are reproducible: the same command run twice produces the same state.
- Consistent mental model and tooling across Docker Compose workloads and SSH-managed hosts.
- `--force` flag available to push a harder refresh when needed.
- Zero new infrastructure dependencies beyond SSH and rsync (already available everywhere).

## Non-Goals

- Full GitOps with automatic reconciliation (addressed in "Follow-up" below).
- Multi-host fleet management or a UI.
- Replacing one-time provisioning scripts (`vm-create.sh`, `lxc-create.sh`).

## Decision

**Use rsync + SSH as the canonical deployment mechanism.**

Each deployable system gets `systems/<system>/scripts/deploy.sh` — a single idempotent script that:

1. rsyncs the system's source directory to the target host.
2. SSHs to the target and runs the appropriate command (`docker compose up` for compose workloads, a setup script for host/service systems).
3. Accepts `--force` for a harder refresh.

A shared library at `scripts/_deploy.sh` provides `rsync_to()` and `ssh_exec()` helpers so per-system scripts stay short (~15 lines).

Three flavors:

| Flavor | Examples | rsync source | Remote command |
| --- | --- | --- | --- |
| **compose** | traefik, n8n, monitoring, litellm, open-webui, adguard-home, mosquitto, uptime-kuma, ntfy | `config/` → `/opt/stacks/<workload>/` | `docker compose -p <name> up -d --remove-orphans` |
| **host** | net-gateway (LXC) | `scripts/` → `/opt/<system>/` | `bash /opt/<system>/bootstrap.sh` |
| **service** | tailscale | `scripts/` → `/opt/<system>/` | `bash /opt/<system>/setup-subnet-router.sh` |

The Docker SSH context (`setup-context.sh`) is retained as an optional convenience for read-only inspection (`docker ps`, `docker logs`). It is explicitly not a deployment path.

## Consequences

- `.env` files (gitignored, created locally from `.env.example`) are synced to target hosts on every deploy. This replaces any manual scp pre-steps and ensures the remote state matches the local source.
- `configs: file:` references in compose files resolve correctly because the files are present on docker-host after rsync (not forwarded from the client).
- Compose workload scripts are nearly identical (9 files, ~15 lines each). The shared library keeps this DRY at the primitive level; per-system scripts remain explicit about their intent.
- Deployment is push-based and manual. Running `deploy.sh` is required for changes to take effect. Drift between repo and running state is possible if a change is made directly on a host.

## Follow-up: evaluating `doco-cd` for pull-based GitOps

The decision above is explicitly a starting point. The next evolution worth evaluating is **`doco-cd`** — a lightweight headless agent (single container per host) that polls a Git repo and applies compose stack changes automatically. This would make the homelab self-reconciling: commit to the repo, the host converges.

Triggers that would justify graduating to `doco-cd`:

- Deploy frequency increases to the point that running `deploy.sh` by hand is friction.
- Drift incidents: a host diverges from the repo state and it goes unnoticed.
- The `--force` workaround is needed regularly (sign that something isn't converging on its own).
- A second docker-host-equivalent host is added, making fleet consistency harder to maintain manually.

Before graduating, evaluate:

- **Repo structure**: does the monorepo layout (one `config/` per system) map cleanly to how `doco-cd` discovers stacks?
- **Secrets**: how does `doco-cd` handle `.env` files that aren't in the repo? (SOPS, external secret provider, or a secrets directory on the host that `doco-cd` merges?)
- **Migration**: can stacks move to `doco-cd` one at a time, or is it all-or-nothing?
- **Agent lifecycle**: what updates and monitors the `doco-cd` agent itself?
