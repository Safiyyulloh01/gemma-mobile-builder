#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# local_build.sh — One-shot: download → convert → APK
# ─────────────────────────────────────────────────────────
#
# Simplifies local builds. Run from repo root.
#
# Prerequisites:
#   - Android NDK r27c+ installed at $ANDROID_NDK_HOME
#   - Hugging Face token at $HF_TOKEN
#   - Python 3.11+
#   - JDK 17+
#
# ─────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

MODEL="${MODEL:-principled-intelligence/gemma-4-E2B-it-text-only}"
QUANT="${QUANT:-q4_k_m}"
NDK="${ANDROID_NDK_HOME:-$HOME/android-ndk-r27c}"

echo "╔══════════════════════════════════════════════╗"
echo "║  Gemma Mobile Builder — Local Build          ║"
echo "╠══════════════════════════════════════════════╣"
echo "║ Model: $MODEL"
echo "║ Quant: $QUANT"
echo "║ NDK  : $NDK"
echo "╚══════════════════════════════════════════════╝"

# Step 1: Download
echo ""
echo "── Step 1/4: Download model ───────────────────"
pip install -q huggingface_hub 2>/dev/null
python3 scripts/download_model.py \
    --model-id "$MODEL" \
    --output-dir models/original \
    --token "${HF_TOKEN}"

# Step 2: Convert to GGUF
echo ""
echo "── Step 2/4: Convert to GGUF ──────────────────"
bash scripts/convert_to_gguf.sh \
    --input-dir models/original \
    --output-dir models/gguf \
    --quant-type "$QUANT"

# Step 3: Build native libs
echo ""
echo "── Step 3/4: Build Android native ─────────────"
bash scripts/build_llamacpp_android.sh \
    --ndk-dir "$NDK" \
    --abi arm64-v8a \
    --output-dir android/app/libs/arm64-v8a

# Step 4: Build APK
echo ""
echo "── Step 4/4: Build APK ────────────────────────"
mkdir -p android/app/src/main/assets/models/
cp models/gguf/gemma-4-e2b-${QUANT}.gguf \
   android/app/src/main/assets/models/gemma-4-e2b.gguf

cd android
./gradlew assembleRelease
cd ..

# Sign
bash scripts/sign_apk.sh \
    --apk-path android/app/build/outputs/apk/release/app-release-unsigned.apk \
    --output-dir dist/

echo ""
echo "==> Done! APK at: dist/gemma-mobile.apk"
echo "==> Size: $(ls -lh dist/gemma-mobile.apk | awk '{print $5}')"
