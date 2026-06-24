#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# export_onnx.sh — Export HF Gemma model → ONNX
# ─────────────────────────────────────────────────────────
set -euo pipefail

MODEL_ID=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --model-id) MODEL_ID="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

echo "==> Exporting $MODEL_ID → ONNX"

pip install -q optimum[onnxruntime] torch --extra-index-url https://download.pytorch.org/whl/cpu

# Use optimum-cli to export
optimum-cli export onnx \
  --model "$MODEL_ID" \
  --task text-generation \
  --framework pt \
  --opset 18 \
  --device cpu \
  "$OUTPUT_DIR"

echo "==> ONNX files:"
ls -lh "$OUTPUT_DIR/"
echo "==> ONNX export complete"
