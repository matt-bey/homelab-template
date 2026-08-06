# SearXNG

Status: Operational

Host: [docker-host](../docker-host/)

Self-hosted metasearch engine providing web search to local LLM tools. Aggregates results from Google, Bing, DuckDuckGo, and others without tracking or accounts. Wired into [Open WebUI](../open-webui/) for the user-facing search toggle and [LiteLLM](../litellm/) for API-level web search tool calls.

Single container, no Redis — stateless and low-resource. Reachable by name on the `traefik-proxy` network from both LiteLLM and Open WebUI (`http://searxng:8080`). The Traefik route exposes it for direct browser use.
