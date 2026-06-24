#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# convert_to_gguf.sh — Convert HuggingFace model → GGUF
# ─────────────────────────────────────────────────────────
set -euo pipefail

INPUT_DIR=""
OUTPUT_DIR=""
QUANT_TYPE="q4_k_m"

while [[ $# -gt 0 ]]; do
  case $1 in
    --input-dir) INPUT_DIR="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --quant-type) QUANT_TYPE="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

echo "==> Converting $INPUT_DIR → GGUF ($QUANT_TYPE)"

# Clone llama.cpp (pinned commit for stability)
LLAMACPP_DIR="/tmp/llama.cpp"
if [ ! -d "$LLAMACPP_DIR" ]; then
  git clone --depth=1 https://github.com/ggerganov/llama.cpp "$LLAMACPP_DIR"
fi

# Build convert tools
pip install -q -r "$LLAMACPP_DIR/requirements.txt" 2>/dev/null || true

# Step 1: Convert HF model to FP16 GGUF
echo "==> Step 1: HF → FP16 GGUF"
python3 "$LLAMACPP_DIR/convert_hf_to_gguf.py" \
  "$INPUT_DIR" \
  --outfile "$OUTPUT_DIR/gemma-4-e2b-f16.gguf" \
  --outtype f16

echo "Step 1 complete: $(ls -lh "$OUTPUT_DIR/gemma-4-e2b-f16.gguf")"

# Step 2: Build llama.cpp tools
echo "==> Step 2: Build llama.cpp quantization tool"
cmake -S "$LLAMACPP_DIR" -B "$LLAMACPP_DIR/build" -DCMAKE_BUILD_TYPE=Release
cmake --build "$LLAMACPP_DIR/build" --target llama-quantize -- -j$(nproc)

# Step 3: Quantize
echo "==> Step 3: Quantize → $QUANT_TYPE"
OUTPUT_NAME="gemma-4-e2b-${QUANT_TYPE}.gguf"

"$LLAMACPP_DIR/build/bin/llama-quantize" \
  "$OUTPUT_DIR/gemma-4-e2b-f16.gguf" \
  "$OUTPUT_DIR/$OUTPUT_NAME" \
  "$QUANT_TYPE"

# Step 4: Cleanup intermediate
echo "==> Cleanup: removing FP16 intermediate"
rm -f "$OUTPUT_DIR/gemma-4-e2b-f16.gguf"

echo "==> Quantized model: $(ls -lh "$OUTPUT_DIR/$OUTPUT_NAME")"
echo "==> Conversion complete"
