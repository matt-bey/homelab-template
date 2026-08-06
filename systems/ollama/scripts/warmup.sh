#!/usr/bin/env bash
set -euo pipefail

# Load a model into VRAM to eliminate cold-start latency on first real request.
# Usage: warmup.sh [model]
# Example: warmup.sh qwen3:8b
# Override default model via OLLAMA_WARMUP_MODEL env var.

MODEL="${1:-${OLLAMA_WARMUP_MODEL:-qwen3.5:9b}}"
OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://localhost:11434}"

echo "Warming up ${MODEL}..."

curl -sf "${OLLAMA_BASE_URL}/api/generate" \
  -H "Content-Type: application/json" \
  -d "{\"model\": \"${MODEL}\", \"prompt\": \"hi\", \"stream\": false}" \
  > /dev/null

echo "${MODEL} loaded."
