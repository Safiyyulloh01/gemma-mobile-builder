package com.gemma.mobile

/**
 * JNI bridge to llama.cpp native library.
 *
 * The native .so is cross-compiled in CI (build_llamacpp_android.sh)
 * and bundled into the APK under jniLibs/<abi>/.
 */
object InferenceEngine {
    private var loaded = false

    init {
        try {
            System.loadLibrary("llama")
            loaded = true
        } catch (e: UnsatisfiedLinkError) {
            android.util.Log.e("InferenceEngine", "Failed to load native lib: ${e.message}")
        }
    }

    /** Returns true if the native library was loaded */
    fun isAvailable(): Boolean = loaded

    /**
     * Generate text from a prompt.
     * This is a placeholder — the actual JNI implementation
     * wraps llama.cpp's inference API.
     */
    fun generate(prompt: String): String {
        if (!loaded) return "Native library not loaded"
        return nativeGenerate(prompt)
    }

    // ── Native methods ────────────────────────────────────
    private external fun nativeGenerate(prompt: String): String
    private external fun nativeLoadModel(modelPath: String): Boolean
    private external fun nativeUnloadModel()
}
