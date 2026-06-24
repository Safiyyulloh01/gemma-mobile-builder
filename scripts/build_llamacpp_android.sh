#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────
# build_llamacpp_android.sh — Cross-compile llama.cpp for Android
# ─────────────────────────────────────────────────────────
set -euo pipefail

NDK_DIR=""
ABI="arm64-v8a"
OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --ndk-dir) NDK_DIR="$2"; shift 2 ;;
    --abi) ABI="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

echo "==> Building llama.cpp for Android ABI=$ABI"

# Toolchain mapping
case "$ABI" in
  arm64-v8a)
    HOST_TAG="linux-x86_64"
    TOOLCHAIN="aarch64-linux-android"
    API_LEVEL=29
    ;;
  armeabi-v7a)
    HOST_TAG="linux-x86_64"
    TOOLCHAIN="armv7a-linux-androideabi"
    API_LEVEL=29
    ;;
  x86_64)
    HOST_TAG="linux-x86_64"
    TOOLCHAIN="x86_64-linux-android"
    API_LEVEL=29
    ;;
  *) echo "Unknown ABI: $ABI"; exit 1 ;;
esac

TOOLCHAIN_DIR="$NDK_DIR/toolchains/llvm/prebuilt/$HOST_TAG"
CC="$TOOLCHAIN_DIR/bin/${TOOLCHAIN}${API_LEVEL}-clang"
CXX="$TOOLCHAIN_DIR/bin/${TOOLCHAIN}${API_LEVEL}-clang++"

LLAMACPP_DIR="/tmp/llama.cpp-android"
if [ ! -d "$LLAMACPP_DIR" ]; then
  git clone --depth=1 https://github.com/ggerganov/llama.cpp "$LLAMACPP_DIR"
fi

BUILD_DIR="$LLAMACPP_DIR/build-android-$ABI"
mkdir -p "$BUILD_DIR"

cmake -S "$LLAMACPP_DIR" -B "$BUILD_DIR" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_SYSTEM_NAME=Android \
  -DCMAKE_SYSTEM_VERSION=$API_LEVEL \
  -DCMAKE_ANDROID_ARCH_ABI=$ABI \
  -DCMAKE_ANDROID_NDK="$NDK_DIR" \
  -DCMAKE_ANDROID_STANDALONE_TOOLCHAIN="$TOOLCHAIN_DIR" \
  -DCMAKE_C_COMPILER="$CC" \
  -DCMAKE_CXX_COMPILER="$CXX" \
  -DLLAMA_METAL=OFF \
  -DLLAMA_CUDA=OFF \
  -DLLAMA_VULKAN=OFF \
  -DLLAMA_NATIVE=OFF \
  -DBUILD_SHARED_LIBS=ON \
  -DLLAMA_STATIC=OFF

cmake --build "$BUILD_DIR" -- -j$(nproc)

# Collect shared libraries
mkdir -p "$OUTPUT_DIR"
cp "$BUILD_DIR"/libllama* "$OUTPUT_DIR/" 2>/dev/null || true
cp "$BUILD_DIR"/libggml* "$OUTPUT_DIR/" 2>/dev/null || true

# Build JNI wrapper library
# (In a real project you'd compile your own JNI bridge here)

echo "==> Android native libs for $ABI:"
ls -lh "$OUTPUT_DIR/"
echo "==> Build complete"
