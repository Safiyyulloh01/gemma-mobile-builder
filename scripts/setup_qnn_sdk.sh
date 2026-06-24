#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# setup_qnn_sdk.sh — Download & extract Qualcomm QNN SDK
# ─────────────────────────────────────────────────────────
#
# The QNN SDK is proprietary — Qualcomm provides it via
# qpm.qualcomm.com. You must download it manually and
# expose the download URL as a GitHub secret.
#
# Set secrets:
#   QNN_SDK_URL — direct download link for qcom-qnn-sdk-*.zip
#   (or provide the zip path manually)
#
# ─────────────────────────────────────────────────────────
set -euo pipefail

OUTPUT_DIR=""
QNN_VERSION="2.28.0.250409"

while [[ $# -gt 0 ]]; do
  case $1 in
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --version) QNN_VERSION="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

echo "==> Setting up QNN SDK v$QNN_VERSION → $OUTPUT_DIR"

mkdir -p "$OUTPUT_DIR"

# Try multiple sources in order
if [ -n "${QNN_SDK_URL:-}" ]; then
  echo "Downloading QNN SDK from QNN_SDK_URL secret..."
  wget -q -O /tmp/qnn-sdk.zip "$QNN_SDK_URL"
  unzip -qo /tmp/qnn-sdk.zip -d "$OUTPUT_DIR"
  echo "==> QNN SDK extracted"
elif [ -n "${QNN_SDK_PATH:-}" ]; then
  echo "Using local QNN SDK path: $QNN_SDK_PATH"
  cp -r "$QNN_SDK_PATH"/* "$OUTPUT_DIR/"
else
  echo "!! QNN SDK not available."
  echo "!! To use the QNN NPU path:"
  echo "    1. Download from https://qpm.qualcomm.com"
  echo "    2. Add QNN_SDK_URL as a GitHub Actions secret"
  echo ""
  echo "Falling back: SKIP QNN optimization"
  mkdir -p "$OUTPUT_DIR/skip"
  exit 0  # non-fatal — CI continues without QNN
fi

echo "==> QNN SDK structure:"
ls -la "$OUTPUT_DIR/" | head -10
