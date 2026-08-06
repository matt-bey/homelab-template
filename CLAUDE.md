# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## System flavors

Systems come in three flavors. Each has a starting set of files; files are always **optional unless they have real content** — don't create empty stubs.

| Flavor                     | Examples                                                  | Distinguishing trait                                            |
| -------------------------- | --------------------------------------------------------- | --------------------------------------------------------------- |
| **Physical compute host**  | `homelab-server`, `dev-workstation`, future NAS / LLM server | Has hardware; hosts one or more workload systems                |
| **Physical appliance**     | `network`, `telephony`, future rack                       | Has hardware; runs firmware, not generalized workloads          |
| **Workload**               | `litellm`, `ollama`, `n8n`, future Pi-hole, MCP servers   | No hardware of its own; runs on a host (link via `Host:` field) |

See `.claude/rules/homelab-conventions.md` for per-flavor file templates.

## Structure

```
adr/             # Cross-system ADRs (rare — most live under systems/<name>/adr/)
blog/            # Blog seed files — raw POC findings and technical notes, YYYYMMDD-<title>.md
docs/            # Cross-cutting reference topics (authored)
datasheets/      # Third-party PDFs and manuals that span multiple systems
inventory.md     # Home lab hardware ledger — "received and in service" only
systems/         # Main content — one directory per running system
tools/           # Cross-cutting lab utilities — test harnesses, analysis scripts, standalone applications
  <name>/        # One directory per tool; no fixed file template — shape follows the tool
  <name>/
    README.md         # Required. What the system is and its current state.
    hardware.md       # Resources the system has — physical specs or VM allocation
    software.md       # Optional — host-level OS/stack overview
    deployment.md     # The system's OS-level identity (hostname, IP, SSH key) — physical or VM
    runbook.md        # Optional — steady-state ops and break-glass procedures
    notes.md          # Optional — free-form lab notebook, date-headered, newest on top
    plan.md           # Optional — current major plan + its execution checklist
    build-log.md      # Optional — as-built history once plan.md execution completes
    progress.md       # Optional — build milestones for systems with no plan.md
    decisions.md      # Optional — minor decisions log (one-liner each)
    adr/              # Architecture Decision Records, numbered from 001
    config/           # Source-of-truth declarative IaC (compose, terraform, ansible, etc.)
    scripts/          # Imperative helpers (setup.sh, deploy.sh, ad-hoc maintenance)
    datasheets/       # Third-party PDFs scoped to this system
.claude/
  rules/         # Behavioral conventions for working in this repo
```

Workload systems typically have only `README.md`, `config/`, and `notes.md` — with a `Host:` line in the README linking to the host system.

## Key conventions

- American English spelling throughout. No emojis in authored content.
- Markdown formatted Prettier-style — single space after list markers, fenced code blocks, sensible line breaks.
- **System naming**: role-driven, not software- or hardware-derived (`homelab-server`, not `proxmox-mini`). Names stay stable through hardware refresh; use `-v2` suffix for side-by-side same-role deployments. Workload systems are an exception — named after the tool they *are* (`n8n`, `ollama`).
- **File naming**: per-system meta-files use lowercase (`hardware.md`, `notes.md`, `plan.md`, etc.). `README.md` and `CLAUDE.md` stay UPPERCASE because they're tool-recognized. ADR files follow `NNN-short-title.md` lowercase-kebab.
- The unit of organization is a **system** under `systems/`, not a project.
- **One fact, one home.** Direction-setting content (where a system is headed) lives in `plan.md`, `adr/`, or `decisions.md` — never duplicated into `README.md`, `software.md`, or `hardware.md`. The README at most has a one-line `Plan:` link (active) or `Build log:` link (completed).
- **Files are optional unless they have content.** Don't create empty stubs. Only `README.md` is required for every system; `hardware.md` is also required for physical systems and recommended for VMs with non-trivial resource allocation.
- System lifecycle status (single axis, on the line below the title in each system's README):
  `Status: Planned | Building | Operational | Degraded | Retired`
  Workload systems carry their own status independent of their host.
- **Workload systems** use a `Host:` line linking to the host system; host systems list inbound workloads in a `Workloads:` section. Most workloads skip hardware/deployment, but VMs (or any workload with its own OS-level identity or non-trivial resource allocation) keep them — these are dual-role systems that are simultaneously workload-of-X and host-of-Y. See conventions file for details.
- `config/` per system is the source of truth for declarative IaC, regardless of tool (Docker Compose, Terraform, Ansible, Kubernetes manifests, systemd units, network device configs). Use tool-named subdirectories when there's enough material to warrant separation; a single file at the top doesn't need a subdir.
- `scripts/` is for imperative helpers — kept distinct from `config/`.
- `runbook.md` is the file you open at 11pm when something is on fire. Operational, not architectural.
- `notes.md` is the lab notebook. Date-headered entries, newest on top. Tag blog-worthy entries with `[journal]` for later extraction.
- `plan.md` carries both the reasoning and the execution checklist for an in-flight direction. When execution completes, it's renamed to `build-log.md` as a historical artifact; future plans for the same system layer chronologically into the same build-log on completion. Standalone `progress.md` is reserved for greenfield builds with no associated plan. Multiple simultaneous plans for one system use descriptive filenames (`plan-gpu-upgrade.md`, etc.) — no `plans/` subdir. None of these files is for documentation TODOs — those are inline `TODO:` markers, surfaced with `grep -rn 'TODO' systems/`.
- Per-machine specifics (hostnames, users, SSH key names) live in the system's `deployment.md`. Scripts default to generic stock values and read overrides from env vars (see conventions file for the pattern).
- ADRs live in `systems/<name>/adr/` for system-specific decisions; root `/adr/` is for cross-system decisions only. Numbered per-location from 001.
- Cross-system plans live with their primary system's `plan.md`; affected systems get a one-line back-reference. If there's truly no primary, use root-level `plans/`.
- Check `inventory.md` before assuming hardware needs to be purchased.
- Third-party reference docs (datasheets, vendor manuals) live in `systems/<name>/datasheets/`. Root `datasheets/` is for docs that span multiple systems.

## No repo-level build system

No CI, no linting, no test suite at the repo level. Individual systems may contain their own scripts or build artifacts scoped to that system.

## Commit style

Use [Conventional Commits](https://www.conventionalcommits.org/): `type(scope): description`.

Types for this repo:

| Type     | Use for                                                          |
| -------- | ---------------------------------------------------------------- |
| `sys`    | New system or major system milestone                             |
| `infra`  | Server / rack / storage / UPS hardware or system-level changes   |
| `net`    | Router, switch, VLAN, firewall, DNS                              |
| `llm`    | Local LLM stack — Ollama, LiteLLM, n8n, Open WebUI, MCP, agents  |
| `docs`   | README, runbook, notes, decisions, ADR, plan prose               |
| `config` | Declarative config (compose, k8s, ansible, terraform, systemd)   |
| `adr`    | New or updated ADR                                               |
| `fix`    | Corrections to docs or configs                                   |
| `chore`  | Repo structure, scripts, housekeeping                            |

Scope is optional but helpful — usually the system name: `docs(network)`, `config(litellm)`, `infra(nas)`.

Write messages that future-you will be glad to read in `git log`. A commit body is encouraged when the *why* isn't obvious from the diff.
