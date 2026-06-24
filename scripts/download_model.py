#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# download_model.py — Download model from Hugging Face
# ─────────────────────────────────────────────────────────
set -euo pipefail

while [[ $# -gt 0 ]]; do
  case $1 in
    --model-id) MODEL_ID="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --token) HF_TOKEN="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

echo "==> Downloading $MODEL_ID → $OUTPUT_DIR"

# Pull model files (exclude safetensors >2GB to save time if we're going to quantize)
# We only need the raw weights for conversion
huggingface-cli download "$MODEL_ID" \
  --local-dir "$OUTPUT_DIR" \
  --local-dir-use-symlinks False \
  --resume-download

# Verify we have essential files
echo "==> Files downloaded:"
ls -lh "$OUTPUT_DIR/" | head -20

# Check for PyTorch / SafeTensors
if ls "$OUTPUT_DIR"/*.safetensors 1>/dev/null 2>&1; then
  echo "==> Detected safetensors format"
elif ls "$OUTPUT_DIR"/*.bin 1>/dev/null 2>&1; then
  echo "==> Detected PyTorch bin format"
else
  echo "!! No weight files found; listing all files:"
  find "$OUTPUT_DIR" -maxdepth 2 -type f | head -30
fi

echo "==> Download complete"
