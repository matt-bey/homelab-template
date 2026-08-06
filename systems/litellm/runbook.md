# LiteLLM — Runbook

## Prerequisites

Before deploying, Ollama on `dev-workstation` must accept remote connections.
See [../ollama/runbook.md](../ollama/runbook.md) — "Remote access" section.

## First-time setup

**1. Create the .env file** (run from repo root):

```bash
cp systems/litellm/config/.env.example systems/litellm/config/.env
```

Edit `.env` and set a real `LITELLM_MASTER_KEY`:

```bash
openssl rand -hex 16 | sed 's/^/sk-/'
```

Leave `ANTHROPIC_API_KEY` as-is — it is a required placeholder, not used for auth.
Leave `OLLAMA_BASE_URL` as-is if `dev-workstation` is at `<dev-workstation-ip>`.

**2. Deploy** (from repo root):

```bash
DOCKER_CONTEXT=docker-host docker compose -p litellm -f systems/litellm/config/compose.yaml up -d
```

**3. Verify the gateway is up:**

```bash
curl http://<docker-host-ip>:4000/health/liveliness
# → {"status":"healthy"}
```

**4. Configure Claude Code** on `dev-workstation` and MacBook:

Add to `~/.zshrc` (or the appropriate shell profile):

```bash
export ANTHROPIC_BASE_URL=http://<docker-host-ip>:4000
export ANTHROPIC_API_KEY=<your-LITELLM_MASTER_KEY>
export CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1
```

`ANTHROPIC_API_KEY` here is the LiteLLM master key — it authenticates Claude Code with
the gateway. The actual Anthropic OAuth token (from `claude login`) is forwarded through
the gateway to Anthropic for subscription billing.

Reload the shell, then confirm Claude Code sees the gateway:

```bash
claude --version   # sanity check
# Use /model in a session to see gateway-discovered models
```

## Steady-state operations

**Check status:**

```bash
DOCKER_CONTEXT=docker-host docker compose -p litellm -f systems/litellm/config/compose.yaml ps
```

**View logs:**

```bash
DOCKER_CONTEXT=docker-host docker compose -p litellm -f systems/litellm/config/compose.yaml logs -f
```

**Restart:**

```bash
DOCKER_CONTEXT=docker-host docker compose -p litellm -f systems/litellm/config/compose.yaml restart
```

**Stop:**

```bash
DOCKER_CONTEXT=docker-host docker compose -p litellm -f systems/litellm/config/compose.yaml down
```

## Upgrading

LiteLLM PyPI versions **1.82.7 and 1.82.8 were compromised** with credential-stealing
malware. The OAuth token forwarding design here means a compromised LiteLLM instance
would have access to Claude subscription credentials — pin to a verified version and
review the changelog before upgrading. See
[BerriAI/litellm#24518](https://github.com/BerriAI/litellm/issues/24518) for the
remediation context.

```bash
DOCKER_CONTEXT=docker-host docker compose -p litellm -f systems/litellm/config/compose.yaml pull
DOCKER_CONTEXT=docker-host docker compose -p litellm -f systems/litellm/config/compose.yaml up -d
```
