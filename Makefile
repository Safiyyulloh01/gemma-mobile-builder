.PHONY: all download convert build-android apk clean

MODEL_ID    ?= principled-intelligence/gemma-4-E2B-it-text-only
QUANT_TYPE  ?= q4_k_m
ANDROID_ABI ?= arm64-v8a
NDK_DIR     ?= $(HOME)/android-ndk-r27c

all: download convert build-android

# --- Download model from Hugging Face ---
download:
	@echo "==> Downloading $(MODEL_ID)"
	python3 scripts/download_model.py \
		--model-id "$(MODEL_ID)" \
		--output-dir models/original \
		--token "$${HF_TOKEN}"

# --- Convert to GGUF ---
convert:
	@echo "==> Converting to GGUF ($(QUANT_TYPE))"
	bash scripts/convert_to_gguf.sh \
		--input-dir models/original \
		--output-dir models/gguf \
		--quant-type "$(QUANT_TYPE)"

# --- Build llama.cpp Android native libs ---
build-android:
	@echo "==> Building llama.cpp for $(ANDROID_ABI)"
	bash scripts/build_llamacpp_android.sh \
		--ndk-dir "$(NDK_DIR)" \
		--abi "$(ANDROID_ABI)" \
		--output-dir android/app/libs/$(ANDROID_ABI)

# --- Build Android APK ---
apk:
	@echo "==> Building APK"
	@mkdir -p android/app/src/main/assets/models/
	@cp models/gguf/gemma-4-e2b-$(QUANT_TYPE).gguf \
		android/app/src/main/assets/models/
	cd android && ./gradlew assembleRelease
	cp android/app/build/outputs/apk/release/app-release-unsigned.apk \
		dist/gemma-mobile-unsigned.apk
	@echo "==> APK ready at dist/gemma-mobile-unsigned.apk"

# --- Clean ---
clean:
	rm -rf models/gguf models/onnx models/original
	rm -rf android/app/libs/
	rm -f dist/*.apk
