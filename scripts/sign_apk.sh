#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# sign_apk.sh — Sign Android APK with apksigner
# ─────────────────────────────────────────────────────────
set -euo pipefail

APK_PATH=""
KEYSTORE=""
KEY_ALIAS=""
KEY_PASSWORD=""
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --apk-path) APK_PATH="$2"; shift 2 ;;
    --keystore) KEYSTORE="$2"; shift 2 ;;
    --key-alias) KEY_ALIAS="$2"; shift 2 ;;
    --key-password) KEY_PASSWORD="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

mkdir -p "$OUTPUT_DIR"

# Zipalign (align for memory-mapping)
ANDROID_SDK="${ANDROID_HOME:-$HOME/android-sdk}"
ZIPALIGN="$ANDROID_SDK/build-tools/34.0.0/zipalign"
APKSIGNER="$ANDROID_SDK/build-tools/34.0.0/apksigner"

ALIGNED_APK="$OUTPUT_DIR/gemma-mobile-aligned.apk"
SIGNED_APK="$OUTPUT_DIR/gemma-mobile.apk"

# If no keystore secret set, generate a debug key
if [ -z "$KEYSTORE" ] || [ "$KEYSTORE" = "" ]; then
  echo "No keystore provided — generating debug key"
  KEYSTORE="/tmp/debug.keystore"
  KEY_ALIAS="debug"
  KEY_PASSWORD="android"
  keytool -genkey -v -keystore "$KEYSTORE" \
    -keyalg RSA -keysize 2048 -validity 10000 \
    -alias "$KEY_ALIAS" -storepass "$KEY_PASSWORD" \
    -keypass "$KEY_PASSWORD" -dname "CN=Gemma,OU=Mobile,O=AI,C=US"
fi

echo "==> Zipaligning..."
"$ZIPALIGN" -p -f 4 "$APK_PATH" "$ALIGNED_APK"

echo "==> Signing..."
"$APKSIGNER" sign \
  --ks "$KEYSTORE" \
  --ks-key-alias "$KEY_ALIAS" \
  --ks-pass "pass:$KEY_PASSWORD" \
  --key-pass "pass:$KEY_PASSWORD" \
  --out "$SIGNED_APK" \
  "$ALIGNED_APK"

echo "==> Verified signature:"
"$APKSIGNER" verify --verbose "$SIGNED_APK"

echo "==> Signed APK: $(ls -lh $SIGNED_APK)"
