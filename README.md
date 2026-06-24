# Gemma Mobile Builder

Automated CI pipeline to build a **fully local, on-device** inference app for **Gemma-4-E2B-it-text-only** on Android (Snapdragon) devices.

## Pipeline Overview

```
HF Model ──→ GGUF (Q4) ──→ Android native .so ──→ Signed APK
                ↓               ↓
         llama.cpp     JNI bridge (InferenceEngine)
```

Two target backends:
| Backend | Runtime | Processor | Speed |
|---------|---------|-----------|-------|
| `cpu`   | llama.cpp GGUF | CPU (ARM NEON) | ~10-25 tok/s |
| `qnn_npu` | QNN context binary | Hexagon NPU | ~30-80 tok/s |

## CI Setup (GitHub Actions)

### 1. Fork / clone this repo

### 2. Add GitHub Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `HF_TOKEN` | **Yes** | Hugging Face token (need license for Gemma-4) |
| `QNN_SDK_URL` | No* | Qualcomm QNN SDK download link (for NPU path) |
| `ANDROID_KEYSTORE` | No | Base64-encoded keystore (auto-generates debug key if missing) |
| `ANDROID_KEY_ALIAS` | No | Keystore alias |
| `ANDROID_KEY_PASSWORD` | No | Keystore password |

*QNN SDK is proprietary — download from [qpm.qualcomm.com](https://qpm.qualcomm.com). Without it, the pipeline still builds the CPU (llama.cpp) path.

### 3. Run the Pipeline

Go to **Actions → Gemma Mobile Builder → Run workflow** → fill in:

- **Model ID**: `principled-intelligence/gemma-4-E2B-it-text-only`
- **Quantization**: `q4_k_m` (recommended for 8GB devices)
- **Target backend**: `cpu` (recommended for first build)
- **Android ABI**: `arm64-v8a` (most modern devices)

### 4. Download the APK

From the **completed run** → Artifacts → `gemma-mobile-apk` → `gemma-mobile.apk`

## Local Build (VPS / Linux machine)

```bash
# Prerequisites: Android NDK r27c+, JDK 17+, Python 3.11+
export HF_TOKEN="hf_..."

# One-shot build
make all

# Or step-by-step
make download
make convert
make build-android
make apk
```

Or use the convenience script:

```bash
bash scripts/local_build.sh
```

## What Gets Built

```
android/
├── app/
│   ├── src/main/
│   │   ├── java/com/gemma/mobile/
│   │   │   ├── MainActivity.kt      # Compose UI
│   │   │   ├── ChatViewModel.kt     # Chat state + inference
│   │   │   ├── InferenceEngine.kt   # JNI bridge to llama.cpp
│   │   │   └── InferenceService.kt  # Foreground service
│   │   ├── assets/models/
│   │   │   └── gemma-4-e2b-q4_k_m.gguf  # Quantized model (bundled)
│   │   └── AndroidManifest.xml
│   └── libs/
│       └── arm64-v8a/
│           └── libllama.so           # Cross-compiled llama.cpp
```

## Architecture

```
┌──────────────────┐     HTTP/local     ┌──────────────────┐
│  Compose UI       │ ←────────────────→ │  InferenceService │
│  (MainActivity)   │    (Foreground)    │  (native thread)  │
└──────────────────┘                     └──────┬───────────┘
                                                │ JNI
                                         ┌──────▼───────────┐
                                         │  libllama.so     │
                                         │  (llama.cpp)     │
                                         └──────┬───────────┘
                                                │
                                         ┌──────▼───────────┐
                                         │  .gguf model     │
                                         │  (mmap'd)        │
                                         └──────────────────┘
```

## Notes

- **License**: Gemma-4 requires accepting terms on Hugging Face. The `HF_TOKEN` must have accepted the license.
- **Memory**: Q4_K_M quantized model is ~1.5-2GB. Devices need ≥6GB free RAM.
- **First launch**: Model is bundled in APK (~1.5GB APK). Install via `adb install`.
- **QNN NPU path**: Requires Qualcomm QNN SDK. Installable from QPM. Without it, falls back to CPU.
