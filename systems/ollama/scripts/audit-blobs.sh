#!/usr/bin/env bash
BLOBS_DIR="/usr/share/ollama/.ollama/models/blobs"
MANIFESTS_DIR="/usr/share/ollama/.ollama/models/manifests"
REMOVE=false

for arg in "$@"; do
  [[ "$arg" == "--rm" ]] && REMOVE=true
done

referenced=$(sudo grep -rh '"digest"' "$MANIFESTS_DIR" \
  | grep -o 'sha256:[a-f0-9]*' \
  | sed 's/sha256:/sha256-/' \
  | sort -u)

echo "=== ORPHANED BLOBS ==="
sudo find "$BLOBS_DIR" -maxdepth 1 -type f | while read -r file; do
  name=$(basename "$file")
  if ! echo "$referenced" | grep -qx "$name"; then
    size=$(sudo du -sh "$file" | cut -f1)
    echo "$size  $name"
    if [[ "$REMOVE" == true ]]; then
      sudo rm "$file"
      echo "      deleted"
    fi
  fi
done

echo ""
echo "=== REFERENCED BLOBS ==="
sudo find "$BLOBS_DIR" -maxdepth 1 -type f | while read -r file; do
  name=$(basename "$file")
  if echo "$referenced" | grep -qx "$name"; then
    size=$(sudo du -sh "$file" | cut -f1)
    echo "$size  $name"
  fi
done
