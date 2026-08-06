# LiteLLM

Status: Operational

Host: [docker-host](../docker-host/)

LLM gateway running on `docker-host`. Acts as a centralized proxy between Claude Code (and other consumers) and model providers — Anthropic API and local Ollama inference on [dev-workstation](../dev-workstation/).

Key design: Claude Code's Pro/Max subscription OAuth token is forwarded through to Anthropic, so subscription billing is preserved. Simple subagent tasks route to local models on `dev-workstation`; primary orchestration stays on Anthropic.

