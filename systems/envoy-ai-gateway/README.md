# Envoy AI Gateway

Status: Building

Host: [k8s-lab](../k8s-lab/)

Envoy AI Gateway v0.6.0 running on a single-node k3s cluster, evaluated as an **MCP
gateway** alongside the existing [litellm](../litellm/) LLM proxy. The goal is a hands-on
POC to guide DBI Digital on controlling and auditing MCP-server access for AI agents.

The POC demonstrates three MCP access-control tiers, authenticated by a real Entra ID
tenant:

| Tier | Server | Access control | Point being proven |
| --- | --- | --- | --- |
| **A** | Grafana MCP | Entra group gate; gateway injects a read-only service-account key | Centralized credential custody + group-based access |
| **B** | Azure DevOps MCP | transparent per-user passthrough | Don't break what works |
| **C** | kubernetes-mcp-server | per-user identity preserved, but the gateway blocks write tools | The agent is strictly less capable than the human it acts as |


## Deployment

Versioned IaC lives in [`config/k8s/`](config/k8s/); install commands and chart versions
are tracked in the plan. The gateway terminates TLS itself (cert-manager + Cloudflare
DNS-01) and is reached at `https://mcp.lab.yourdomain.com`, which resolves to the k8s-lab
node (`<k8s-lab-ip>`) via an AdGuard A-record override of the `*.lab.yourdomain.com`
wildcard. Secrets (Cloudflare token, Grafana SA key, Entra app IDs) are created as
in-cluster Secrets, never committed — see [`config/.env.example`](config/.env.example)
for their shape.

| Layer | Namespace | What |
| --- | --- | --- |
| Data plane | `envoy-gateway-system` | Envoy Gateway v1.8.0 (+ Gateway API v1.4.x CRDs) |
| Control plane | `envoy-ai-gateway-system` | Envoy AI Gateway v0.6.0 controller |
| TLS | `cert-manager` | cert-manager v1.20.2 |
| App | `aigw` | `Gateway`, `MCPRoute`s, `Backend`s, and the `mcp.lab.yourdomain.com` cert |
