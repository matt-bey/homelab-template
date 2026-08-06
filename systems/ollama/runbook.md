# Ollama — Runbook

Operational notes for the Ollama service. Runs on the host machine (see [README.md](README.md) for current `Host:`).

## Enable the service (one-time)

The official Ollama installer creates a systemd service but does not enable auto-start.
Run this once to make Ollama start on boot and stay running:

```bash
sudo systemctl enable --now ollama
```

Confirm it is running:

```bash
systemctl status ollama
```

## Remote access (required for LiteLLM on docker-host)

Ollama defaults to `127.0.0.1:11434` and rejects connections from other hosts. LiteLLM on
`docker-host` needs to reach it, so Ollama must bind on all interfaces.

Add an override to the systemd service unit:

```bash
sudo systemctl edit ollama
```

In the editor, add:

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_KEEP_ALIVE=1h"
```

`OLLAMA_KEEP_ALIVE` controls how long a model stays loaded in VRAM after the last request.
Default is `5m`. `1h` avoids cold-start latency (~30s for qwen3.5:9b) for any session within
the hour. Use `-1` to never unload (model stays in VRAM until service restarts).

Then reload and restart:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
```

Confirm the change:

```bash
sudo ss -tlnp | grep 11434    # should show 0.0.0.0:11434
```

Note: this opens Ollama to all LAN hosts. Fine for a private home network; revisit if
the network gets VLANned into a less-trusted zone.

## Use a model

```bash
ollama list                  # show installed models
ollama run <model>           # interactive prompt
ollama pull <model>          # download a model
```

## Stop / restart

```bash
sudo systemctl stop ollama
sudo systemctl restart ollama
```

## Common diagnostics

```bash
journalctl -u ollama -e      # recent logs
journalctl -u ollama -f      # follow logs live
```

Host-level GPU monitoring (`nvidia-smi`, `nvidia-smi pmon`) lives in the host's runbook — see [../dev-workstation/runbook.md](../dev-workstation/runbook.md).

## Failure modes seen / suspected

None recorded yet. Add date-stamped entries as they happen — symptom, what you tried, what worked.
