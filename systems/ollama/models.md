# Ollama — Models

Canonical model list for this instance. Run [`scripts/sync-models.sh`](scripts/sync-models.sh) to pull any missing models or refresh to latest.

## qwen3.5:4b — Fast / Light

~2.5 GB VRAM, ~70–90 tok/s. Small MoE model with thinking mode. Use when speed and low memory footprint matter more than depth — quick lookups, formatting, short drafts.

Example tasks:

- Quick syntax or flag lookups
- Reformat or transform structured data (JSON, CSV, YAML)
- Generate a short commit message or PR description
- Summarize a brief log or error trace

## qwen3.5:9b — Fast Daily Driver

~6.6 GB VRAM, ~35–42 tok/s. Sparse MoE architecture with thinking mode. Substantially better quality than llama3.1:8b at similar speed — 81.7 on GPQA Diamond, 256K context window. Supports structured tool calling via the API. Use when latency matters more than depth.

Example tasks:

- Quick syntax or flag lookups ("what's the rsync flag for...")
- Summarize a log dump or error trace
- Generate a commit message or PR description from a diff
- Format or transform structured data (JSON, CSV, YAML)
- Drive an n8n or LiteLLM agent loop where round-trip speed matters

## qwen2.5-coder:14b — Coding (chat only)

~10 GB VRAM, ~25 tok/s. Purpose-built for code; outperforms generic 14B models on HumanEval. Handles Python, TypeScript, and Go well without fine-tuning.

**Tool calling limitation:** This model does not support structured tool calls via the Ollama API — it outputs tool-call JSON as plain text in the `content` field rather than `tool_calls[]`. Use it for chat-based code writing and review in Open WebUI only; it cannot drive an agent loop.

Example tasks:

- Write a function from a plain-English description
- Review code for bugs, anti-patterns, or security issues
- Refactor a script for readability or performance
- Explain what an unfamiliar regex, shell pipeline, or macro does
- Generate a Docker Compose, Terraform snippet, or systemd unit

## phi4:14b — STEM / Math / Analytical

~8.5 GB VRAM, ~22–26 tok/s. Microsoft's 14B model trained on heavily curated synthetic and academic data. Outperforms Llama 3.1 70B on several math and STEM benchmarks while fitting in 12 GB. Weaker than qwen3.5 on tool calling and long-context retrieval — use it for precision analytical work, not agent loops.

Example tasks:

- Work through a math or statistics problem with a full solution
- Analyze a technical specification, formula, or algorithm for correctness
- Review code for subtle logic errors and edge cases
- Evaluate a design argument with rigorous reasoning
- Explain a physics, chemistry, or engineering concept with precision
