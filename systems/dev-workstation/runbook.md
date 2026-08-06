# Dev Workstation — Runbook

Steady-state ops for the Ubuntu desktop. The box is physically accessible at the basement workbench, so most ops happen locally; SSH is available for remote work.

For workload-specific operations, see the workload system's runbook:

- [../ollama/runbook.md](../ollama/runbook.md) — LLM inference lifecycle and diagnostics

## Watch the GPU

```bash
watch -n 1 nvidia-smi        # 1-second refresh of utilization, memory, temp, power
nvidia-smi pmon              # per-process GPU usage
```

## System snapshot


## Common diagnostics

```bash
dmesg -T | tail -100         # recent kernel messages — useful for GPU/driver issues
sensors                       # temps (needs lm-sensors installed and `sudo sensors-detect` run once)
```

## Failure modes seen / suspected

None recorded yet. Add date-stamped entries as they happen — symptom, what you tried, what worked.
