# Android ProGuard rules for Gemma Mobile
-keep class com.gemma.mobile.InferenceEngine { *; }
-keep class com.gemma.mobile.ChatViewModel { *; }

# Keep JNI methods
-keepclasseswithmembernames class * {
    native <methods>;
}
