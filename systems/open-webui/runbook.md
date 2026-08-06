# Open WebUI — Runbook

## Prerequisites

LiteLLM must be running on `docker-host`. See [../litellm/runbook.md](../litellm/runbook.md).

## First-time setup

**1. Create the .env file:**

```bash
cp systems/open-webui/config/.env.example systems/open-webui/config/.env
```

Edit `.env` and set `OPENAI_API_KEY` to the same value as `LITELLM_MASTER_KEY` in
`systems/litellm/config/.env`.

**2. Deploy** (from repo root):

```bash
DOCKER_CONTEXT=docker-host docker compose -p open-webui -f systems/open-webui/config/compose.yaml up -d
```

**3. Verify:**

```bash
curl -s -o /dev/null -w "%{http_code}" http://<docker-host-ip>:3000
# → 200
```

**4. Open in browser:**

`http://<docker-host-ip>:3000`

On first visit, create an admin account. Subsequent users require an invite or admin approval
(default behavior — change in Admin Panel > Settings > Users if needed).

## Steady-state operations

**Check status:**

```bash
DOCKER_CONTEXT=docker-host docker compose -p open-webui -f systems/open-webui/config/compose.yaml ps
```

**View logs:**

```bash
DOCKER_CONTEXT=docker-host docker compose -p open-webui -f systems/open-webui/config/compose.yaml logs -f
```

**Restart:**

```bash
DOCKER_CONTEXT=docker-host docker compose -p open-webui -f systems/open-webui/config/compose.yaml restart
```

**Stop:**

```bash
DOCKER_CONTEXT=docker-host docker compose -p open-webui -f systems/open-webui/config/compose.yaml down
```

## Upgrading

```bash
DOCKER_CONTEXT=docker-host docker compose -p open-webui -f systems/open-webui/config/compose.yaml pull
DOCKER_CONTEXT=docker-host docker compose -p open-webui -f systems/open-webui/config/compose.yaml up -d
```

Chat history and user accounts are persisted in the `open-webui-data` named volume and survive
image upgrades. The volume is not removed by `down` — only `down -v` removes it.

## Failure modes seen / suspected

None recorded yet. Add date-stamped entries as they happen — symptom, what you tried, what worked.
