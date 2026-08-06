# Home Lab Conventions

When working in this repository, follow these conventions. This is the canonical reference behind the summary in `CLAUDE.md` — read this whenever a homelab convention question comes up.

## Repo shape

The unit of organization is a **system** under `systems/<name>/`. A system is a running thing in the home lab — a piece of network infrastructure, a server, an appliance, a single workload (e.g., LiteLLM, n8n), etc. Systems do not have a build lifecycle like a tinker-lab project does; they have an operational status.

This entire repository is private. There is no publish pipeline. Don't worry about sanitizing file content for an outside reader — write for future-me. The convention of keeping machine-identity specifics in `deployment.md` is preserved purely as a separation-of-concerns convention, not for privacy.

## System naming

System names are **role-driven** — the name describes what the system does in the homelab, not the software currently running on it or the specific hardware model.

- Good: `homelab-server`, `dev-workstation`, `network`, `telephony`, `n8n`, `ollama`
- Avoid: `proxmox-mini` (software-derived — what if Proxmox is ever replaced?), `kron-k1` (hardware-model-derived — what if the box is replaced with different hardware?), `mini-pc` (form-factor-only — ambiguous if more than one exists)

Role-driven names stay stable through hardware refresh. When an aging server gets replaced with new hardware doing the same role, the system entry keeps its identity. Same when the software stack changes — the name still fits.

For side-by-side deployments of the same role (e.g., two backup-pair servers), use a numeric or version suffix: `homelab-server-v2`, `homelab-server-02`.

**The decision rule — ask whether swapping the tool would require touching other systems' configs.** If yes, the specific tool is load-bearing: other systems reference it by name, label, or endpoint (every container has Traefik labels; LiteLLM points at `ollama:11434` by name). Use the tool name. If no, only the system itself would change and its consumers don't care what's underneath (`monitoring` could be Prometheus+Grafana today, Netdata tomorrow — nothing else changes). Use a role name.

When in doubt: `monitoring`, `dns`, `proxy` are roles. `traefik`, `ollama`, `n8n`, `litellm` are tools that own their consumers' config.

Hostnames don't have to match system names but usually should. When they diverge — as with `dev-workstation` carrying the legacy `YOUR-WORKSTATION` hostname — document the reason in `deployment.md`.

## File naming

Per-system meta-files use lowercase: `hardware.md`, `software.md`, `deployment.md`, `runbook.md`, `notes.md`, `plan.md`, `build-log.md`, `progress.md`, `decisions.md`. ADR files follow the `NNN-short-title.md` lowercase-kebab pattern.

Two exceptions stay UPPERCASE because tools and humans both recognize them:

- `README.md` — at every directory level. GitHub, IDEs, and file browsers give it special treatment, and `ls` sorts it to the top of mixed listings.
- `CLAUDE.md` — at the repo root. Claude Code specifically looks for this exact filename.

The lowercase-by-default rule applies to any new per-system file (e.g., a `provisioning.md` would be lowercase, not `PROVISIONING.md`). Avoid mixed-case (`Hardware.md`) and SCREAMING_SNAKE (`HARDWARE_NOTES.md`).

## System flavors

Systems come in three flavors. The flavor determines which files are *typical*, but files are always **optional unless they have real content** — don't create empty stubs.

### Physical compute host

A box that runs an OS and hosts one or more workload systems. Examples: `homelab-server`, `dev-workstation`, future NAS, future dedicated LLM server.

Typical files:

- `README.md` (required) — slim orientation doc; lists workloads running on the host
- `hardware.md` (required) — deployed hardware specs
- `deployment.md` — hostname, IPs, SSH key, account references
- `software.md` — OS, base packages, system-level config not specific to any one workload
- `runbook.md` — operations and break-glass for the host itself (not its workloads)
- `notes.md` — lab notebook
- `plan.md` — when there's a meaningful plan in flight for the host
- `config/` — typically thin: host-level configs like cloud-init templates or systemd units. Workload configs live in workload systems.

### Physical appliance

Hardware that runs firmware rather than a general-purpose OS, or a passive piece of infrastructure. Examples: `network` (router, switches, cabling), `telephony` (HT802 ATA + analog phones), future wall rack, future UPS.

Typical files:

- `README.md` (required) — slim orientation doc
- `hardware.md` (required) — deployed gear and topology
- `deployment.md` — accounts, portals, identifiers (e.g., DHCP reservations, ISP account)
- `runbook.md` — operations (power cycle order, common diagnostics)
- `notes.md` — lab notebook
- `plan.md` — when there's a meaningful plan in flight
- `config/` — device configuration exports (UniFi backups, switch configs, etc.)

Usually no `software.md`.

### Workload

A service or stack running on a physical host. Examples: `litellm`, `ollama`, `n8n`, `open-webui`, future `pi-hole`, future MCP servers.

Typical files:

- `README.md` (required) — includes a `Host:` line linking to the host system
- `config/` — the IaC for the workload (compose.yaml, manifests, etc.)
- `notes.md` — lab notebook for this workload
- `plan.md` — when there's a meaningful plan in flight

Typically no `hardware.md` or `deployment.md` — the hardware belongs to the host, and the workload usually just runs as a container/service with no OS-level identity of its own. Use the `Host:` reference instead. If something needs to be said about *how it deploys onto the host* (port mappings, volume paths, env shape), put it in the README or alongside the compose file in `config/`.

**Exception — dual-role systems.** VMs and other workloads with their own OS-level identity (hostname, IP reservation, SSH key, admin accounts) and/or non-trivial resource allocation (vCPU/RAM/disk, GPU or device passthrough, dedicated NIC) keep deployment.md and hardware.md respectively. See "Dual-role systems" below.

### Dual-role systems

Some systems are simultaneously workloads (of one thing) and hosts (of others). A Docker host VM running on `homelab-server` that hosts `n8n`, `litellm`, and `open-webui` is the canonical example: it's a workload from homelab-server's perspective and a host from the perspective of the containers running inside it.

These systems carry both:

- A `Host:` line in the README pointing at the system that hosts them
- A `Workloads:` section in the README listing what runs on them

They typically use the full physical-host file template — `hardware.md` for the virtual resource allocation, `software.md` for the in-VM OS and stack, `deployment.md` for the VM's own hostname/IP/SSH key, plus `notes.md` and the rest — *plus* the workload's `Host:` line at the top of the README.

The takeaway: flavors aren't mutually exclusive. A system fills a flavor *per relationship*, not as a permanent identity. The "Workload" / "Physical compute host" / "Physical appliance" split is a starting template, not a final classification.

## System lifecycle status

Every system's `README.md` has a `Status:` line directly under the title:

```
Status: Operational
```

Same vocabulary across all three flavors:

| Status        | Meaning                                                                    |
| ------------- | -------------------------------------------------------------------------- |
| `Planned`     | Documented in advance of acquisition or stand-up; nothing deployed yet.    |
| `Building`    | Stood up but not yet in steady state. Active config churn expected.        |
| `Operational` | Working as intended. Most systems live here most of the time.              |
| `Degraded`    | Partially working with known issues. Details in `notes.md` / `runbook.md`. |
| `Retired`     | Decommissioned. Kept for historical reference.                             |

A workload system carries its own status independent of its host. `litellm` can be `Planned` while `homelab-server` is `Operational` — each system describes one thing, so each status describes one thing.

## System file purposes

Canonical reference for what content goes in each file. Use this when deciding what to read, edit, or create.

| File / Dir            | Purpose                                                                                                                                                                                                                                                                |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `README.md`           | Orientation only. Title, status, plain-English description, `Host:` line (workload flavor), `Workloads:` listing (host flavor), one-line link to `docs/physical-layout.md` for physical systems, one-line `Plan:` link to `plan.md` if a plan is in flight (or `Build log:` link to `build-log.md` if the build is complete). Target ~20 lines. Does not duplicate content from hardware/software/deployment. |
| `hardware.md`         | Description of the resources the system has. Physical systems: chips, cards, cabling, power draw, cooling, what's racked. VMs and other virtualized systems with non-trivial allocation: vCPU, RAM, virtual disks, passthrough devices, attached NICs. Skip when the system just uses whatever the host provides. |
| `software.md`         | OS, runtime, and stack at the host level. Generic, reproducible content — versions, package lists, system-level configuration not specific to any one workload. Optional; many systems don't need it.                                                                     |
| `deployment.md`       | The system's own OS-level identity: hostnames, usernames, SSH key names, IP addresses, MAC addresses, account/portal references. Anything machine-identity-specific that scripts pull from env vars. Applies to anything with its own addressable presence — physical machines and VMs both qualify. Skip for containers/services that inherit their host's identity. |
| `runbook.md`          | Steady-state operations and break-glass. Common tasks (restarts, log locations, credential rotation), failure modes, recovery steps. The thing you open at 11pm when something is on fire. Keep operational, not architectural.                                          |
| `notes.md`            | Free-form lab notebook. Date-headered entries, newest on top. Motivation, observations, stuck points, dated decisions while they're still being worked out. Tag blog-worthy entries with `[journal]`.                                                                     |
| `plan.md`             | Current major plan for the system. Long-form working document — where messy thinking lives while a direction is being worked out, plus the execution checklist as the plan moves into action. References ADRs as decisions settle. Renamed to `build-log.md` when execution is complete — see "Plan completion" below. See "Multiple simultaneous plans" for the multi-plan naming pattern. |
| `build-log.md`        | As-built history of the system. Created by renaming `plan.md` once execution is complete and the system has reached its target operational state. Preserves the structured narrative: goals, design choices, phased execution checklist with checkboxes intact (as proof-of-work), end-to-end verification, resolved open questions. Operationally-useful content should be extracted to `runbook.md` first; settled design decisions should already live in `decisions.md` or `adr/`. When future build phases generate new plans for the same system, fold them into the existing `build-log.md` as dated sections on completion — one build-log per system, growing chronologically. |
| `progress.md`         | In-flight build milestones for systems with no associated `plan.md` — typically greenfield builds with a known sequence and no real trade-offs to weigh. When there *is* a `plan.md`, the execution checklist lives inside it. **Not** for documentation TODOs (those are inline `TODO:` markers).                                                                              |
| `decisions.md`        | Minor decisions log. One short entry per decision (what / why / alternatives briefly considered). For choices too small for an ADR but where future-me will still want the reasoning.                                                                                     |
| `adr/NNN-<title>.md`  | Architecture Decision Records — settled decisions with full context, alternatives, trade-offs, and consequences. Numbered per-system from 001.                                                                                                                            |
| `config/`             | Source of truth for declarative IaC. See "IaC organization in `config/`" below.                                                                                                                                                                                          |
| `scripts/`            | Per-system imperative helpers (`setup.sh`, `deploy.sh`, ad-hoc maintenance). See "Scripts" below.                                                                                                                                                                         |
| `datasheets/`         | Third-party PDFs, vendor manuals, and reference docs scoped to this system.                                                                                                                                                                                              |

### Direction-setting content has one home

Where a system is **headed** lives in `plan.md`, `adr/`, or `decisions.md`. Never in `README.md`, `software.md`, or `hardware.md`. The README at most has a one-line `Plan:` link to `plan.md` (or `Build log:` link to `build-log.md` once the plan completes).

The split between plan / ADR / decisions:

- **plan.md** — the journey *and* its execution. Long-form working draft where you walk through trade-offs and open questions, plus the checklist of work-to-be-done once thinking firms up. Most systems have at most one plan in flight at a time; see "Multiple simultaneous plans" below for the rare case where a system has more than one. Renamed to `build-log.md` when execution is complete (see "Plan completion" below).
- **build-log.md** — the as-built history. The retired plan, kept as a structured historical artifact for future-me reading the system months or years later.
- **ADR** — the destination, snapshot. Settled decision with full context. Immutable once accepted (can be superseded by a later ADR).
- **decisions.md** — the one-liner log. Small choices with brief reasoning. Not worth an ADR but worth recording.

### Multiple simultaneous plans

Most systems have at most one plan in flight at a time. When a system genuinely has two distinct simultaneous plans, promote `plan.md` to descriptive per-plan filenames at the top of the system directory: `plan-gpu-upgrade.md`, `plan-bios-flash.md`, etc. The README's `Plan:` line expands to a short bullet list of links. Don't introduce a `plans/` subdirectory — plans are transient (renamed to `build-log.md` on completion), so a flat filename pattern is lighter than a subdir that's mostly empty.

The same pattern applies to standalone `progress.md` in the rare case a system has two unrelated greenfield builds going at once: `progress-<name>.md`.

Before assuming you have multiple plans, check whether the second one is actually a downstream consequence of the first (one plan, two phases), small enough to live in `decisions.md` instead, or still an open question that hasn't crystallized into a real plan yet (lives in `notes.md` "Open questions"). Multi-plan situations are real but rarer than they first appear.

### Plan completion

When a plan's execution is complete and the system has reached its target operational state, retire the plan by renaming it to `build-log.md`:

```bash
git mv systems/<name>/plan.md systems/<name>/build-log.md
```

Update the file:

- Title: `# <System> — Plan` → `# <System> — Build Log`.
- Add a `Completed: YYYY-MM-DD` line under the title.

Update cross-references:

- The system's README `Plan:` line becomes `Build log:` and points at the new filename.
- Any other systems that cross-link to the plan get the same update.

Before retiring, make sure operationally-useful content has a permanent home outside the build-log:

- Verification steps that future-me will want to re-run → `runbook.md`.
- Settled design decisions → `decisions.md` or `adr/`.
- The execution checklist itself stays in the build-log with checkboxes intact, as proof-of-work and historical record.

Future build phases for the same system fold into the existing `build-log.md` as dated sections on completion — multi-plan cases (`plan-gpu-upgrade.md`, `plan-bios-flash.md`) collapse into a single `build-log.md` chronologically. One build-log per system.

### Defaults for new content

- Anything that mentions a specific hostname, username, SSH key name, or IP → `deployment.md`.
- Narrative, reflective, motivational, or dated observation → `notes.md`.
- Open question, trade-off being thought through, or execution checklist for an in-flight direction → `plan.md`.
- In-flight build milestones with no associated plan (rare; greenfield builds with no real trade-offs) → `progress.md`.
- Settled decision with alternatives considered → `adr/` (worth full reasoning) or `decisions.md` (one-liner).
- Operational thing future-me-at-11pm will need → `runbook.md`.
- Declarative configuration the system needs to run → `config/`.
- Imperative helper script → `scripts/`.
- Missing data that needs to be captured (e.g., run `lsblk`) → inline `TODO:` marker where the data should live.

## IaC organization in `config/`

`config/` holds declarative IaC for the system, regardless of tool. Use tool-named subdirectories when there's enough material to warrant separation; a single file at the top doesn't need a subdir.

Examples:

```
systems/litellm/config/
  compose.yaml                # Docker Compose convention — at the top
  .env.example                # Shape of secrets; real .env stays gitignored

systems/homelab-server/config/
  terraform/
    main.tf
    .terraform.lock.hcl
  ansible/
    playbooks/
    roles/
  cloud-init/
    docker-host.yaml

systems/network/config/
  unifi/
    config-backup.unf
  switches/
    <hostname>.cfg
```

Rules of thumb:

- `compose.yaml` lives at the top of `config/` if there's only one Compose stack. If there are several, group by stack name: `config/compose/<stack>/compose.yaml`.
- Tool-specific dotfiles (`.terraform.lock.hcl`, `ansible.cfg`) live alongside their tool's content.
- Compiled or derived artifacts (Terraform state, Ansible facts cache, real `.env` files) are gitignored.
- `scripts/` stays separate — imperative helpers are not declarative IaC.

## Cross-system plans

When a plan touches multiple systems, default to **plan-lives-with-primary-system**:

- The primary system is usually the one being **introduced or substantially changed**. For "add LiteLLM on `homelab-server` that calls Ollama on `dev-workstation`," the primary system is LiteLLM (the new workload), so the plan lives at `systems/litellm/plan.md`.
- Affected systems get a one-line back-reference in their README — typically a `Related plans:` section, or a more specific section like `Inbound references:` on a host that's being targeted by another system's plan.

If a plan genuinely has no primary system, use a root-level `plans/<plan-name>.md`. Don't pre-create the `plans/` directory; add it when the first such plan needs it.

## Blog-fodder tagging

notes.md is the lab notebook. Some entries will become future blog posts; most won't. Tag the candidates inline so they can be extracted later:

```markdown
## 2026-05-18 — Why we picked Ubiquiti over OPNsense [journal]

...
```

Surface tagged entries with `grep -rn '\[journal\]' systems/`. No tooling beyond that — the blog use case is real but not primary for this repo.

## Documentation TODOs

Missing content lives as inline `TODO:` markers where it should eventually go. Don't track doc-debt in `progress.md` or a dedicated file.

```markdown
| Field      | Value                                    |
| ---------- | ---------------------------------------- |
| Boot drive | TODO: capture via `lsblk` and `smartctl` |
```

Surface all doc-debt across the repo with:

```bash
grep -rn 'TODO' systems/ docs/
```

Acquisition-style TODOs (require running a command on the actual machine) and writing-style TODOs (need a paragraph drafted) live together — the distinction isn't worth tracking separately.

## Scripts

Per-system setup and deploy scripts source machine identity from env with descriptive variable names and sensible defaults:

```bash
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519_macbook}"
TARGET="${TARGET:-admin@docker-host.local}"
REMOTE_DIR="${REMOTE_DIR:-/opt/stacks/myapp}"
```

Per-machine overrides go in `~/.zshrc` (or equivalent) as `export SSH_KEY=~/.ssh/<keyname>` — never hardcoded in the script. The actual hostnames, users, and key names for each machine are recorded in that system's `deployment.md`.

Scripts in `setup.sh` must be idempotent — safe to run multiple times against the same machine.

The root `scripts/` directory holds cross-system reusable scripts. Currently: `scripts/_deploy.sh` — shared `rsync_to()` and `ssh_exec()` helpers sourced by every per-system `deploy.sh`. Per-system scripts live in `systems/<name>/scripts/`; add to `scripts/` only when a script is genuinely reusable across systems.

## Architecture decisions

- System-specific ADRs belong in `systems/<name>/adr/` — not in the root `/adr/`.
- Root `/adr/` is reserved for decisions that genuinely span multiple systems (e.g., network addressing scheme, naming convention for all hosts).
- ADR filenames follow `NNN-short-title.md` (e.g., `003-vlan-segmentation.md`). Numbered per-location starting from 001.
- ADR shape: **Status**, **Date proposed**, **Date accepted**, **Context**, **Goals**, **Non-Goals**, **Decision**, **Consequences**.
- An ADR can supersede an earlier ADR — the older one's status becomes `Superseded by NNN`, and the new one references the old in its Context.
- ADRs are written when a decision is **settled enough to crystallize**. Active messy thinking lives in `plan.md` until then.

## Inventory

- Add items to `inventory.md` only once received **and in service**. Items on order or under consideration don't belong here.
- Unlike a parts-on-shelf ledger, most home lab assets are mounted and deployed — entries are short, focused on identity (model, role) rather than build state.
- There is no `## On Radar` section. Speculative wishes live in the relevant system's `notes.md` or `plan.md`.
- `hardware.md` per system references hardware in use; it doesn't duplicate the inventory entry, just describes how it's deployed and wired.

## Reference documents

- Third-party PDFs, datasheets, and vendor manuals live in `systems/<name>/datasheets/`.
- Root-level `datasheets/` is for docs that genuinely span multiple systems (e.g., a switch manual that applies to the whole network).
- `docs/` is for authored cross-cutting topics only — never drop downloaded files there.

## Tools

`tools/` is for cross-cutting lab utilities that are not systems and not simple shell helpers. Each tool gets its own subdirectory: `tools/<name>/`.

**Distinction from root `scripts/`:** Root `scripts/` holds reusable shell functions sourced by per-system deploy scripts (e.g., `_deploy.sh`). `tools/` holds standalone applications — things with their own dependencies, configuration, and output directories that happen to operate on the lab infrastructure rather than constitute part of it.

**Distinction from `systems/`:** Tools have no operational status. They don't run persistently. They're not infrastructure — they're things you run *against* infrastructure to measure, test, or inspect it.

**Shape:** No fixed file template. A tool directory contains whatever the tool needs. Common files:

- `decisions.md` — minor decisions for this tool (same format as per-system decisions.md)
- `requirements.txt` / `pyproject.toml` — Python deps, if applicable
- `.gitignore` — exclude derived outputs (results, venvs, caches)
- `.env.example` — shape of required env vars; real `.env` stays gitignored

A `README.md` is not required but is appropriate when the setup or invocation is non-obvious.

**Currently:**

- `tools/benchmark/` — multi-system LLM benchmark harness. Runs `claude -p` tasks against a test codebase, captures timing via Ollama logs, scores responses via LLM-as-judge. Tests the Ollama + LiteLLM + Claude Code routing stack as an integrated whole.
- `tools/signal-weather/` — given a time window, fetches the ota-tv probe's per-station `ss`/`snq`/`seq` from Prometheus and surface wind from the IEM ASOS archive, merges them on a common UTC grid, and plots a stacked overlay (`snq` the bottleneck, `seq` the artifact canary, `ss` a control) to test whether the reception sag is wind-driven. One command (just `--start`/`--end`; lab URL + service-account token defaulted via `.env`); outputs a merged CSV, an overlay PNG, and an LLM-ready markdown summary.

## Cross-references and shareables

- Inside this repo, link freely between systems with relative paths (`../<other-system>/README.md`).
