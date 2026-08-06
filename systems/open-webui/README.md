# Open WebUI

Status: Operational

Host: [docker-host](../docker-host/)

Chat interface for local LLM models running on [docker-host](../docker-host/). Connects to [LiteLLM](../litellm/) as its model backend — all requests go through the gateway rather than directly to Ollama.

Scope: local models only (qwen3.5:9b via Ollama on [dev-workstation](../dev-workstation/)). Claude Code keeps its own separate OAuth forwarding path through LiteLLM.
