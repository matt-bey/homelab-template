#!/usr/bin/env bash
set -euo pipefail

# Pull all canonical Ollama models for this instance.
# See systems/ollama/models.md for descriptions and example use cases.
# Safe to re-run — ollama pull is idempotent (skips if already current).

MODELS=(
    "qwen3.5:4b"         # fast / light
    "qwen3.5:9b"         # fast daily driver
    "qwen2.5-coder:14b"  # coding (chat only — no tool calling)
    "phi4:14b"           # STEM / math / analytical
)

for model in "${MODELS[@]}"; do
    echo "==> ${model}"
    ollama pull "${model}"
done

echo ""
echo "All models current. Run 'ollama list' to verify."
