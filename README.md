# homelab-template

A monorepo template for organizing a personal home lab — servers, networking, and local LLM infrastructure.

## What this is

A structured approach to treating your home lab as private infrastructure-as-code + historical narrative. The unit of organization is a running **system** — a physical server, network appliance, VM, or container workload — not a project.

Each system has a small set of optional files for different concerns: operational identity, hardware specs, declarative config, runbooks, lab notes, plans, and decisions. The full convention set is in `CLAUDE.md` and `.claude/rules/homelab-conventions.md`.

## Structure

```
systems/         # One directory per running system
  <name>/
    README.md    # Required — what the system is and its current status
    hardware.md  # Physical specs or VM resource allocation
    config/      # Source-of-truth declarative IaC (Compose, Terraform, etc.)
    notes.md     # Lab notebook — date-headered entries, newest on top
    plan.md      # In-flight plan + execution checklist
    ...          # See CLAUDE.md for the full file inventory
adr/             # Cross-system Architecture Decision Records
docs/            # Cross-cutting authored reference topics
scripts/         # Cross-system reusable helper scripts
.claude/rules/   # Claude Code conventions for this repo
```

## Getting started

1. Clone or fork this repository.
2. Read `CLAUDE.md` for the system model and key conventions.
3. Replace the example systems under `systems/` with your own.
4. Keep only files that have real content — empty stubs are explicitly discouraged.
