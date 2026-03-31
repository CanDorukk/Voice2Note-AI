package com.example.voice_2_note_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_WHISPER,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "transcribe" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<*, *>
                    val modelPath = args?.get("modelPath") as? String
                    val audioPath = args?.get("audioPath") as? String
                    val nativeResult = try {
                        WhisperNative.transcribe(
                            modelPath = modelPath,
                            audioPath = audioPath,
                        )
                    } catch (e: Throwable) {
                        "[Whisper native stub] failed: ${e.message}"
                    }
                    // Sonraki adım: whisper.cpp ile gerçek transkript (JNI).
                    result.success(nativeResult)
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val CHANNEL_WHISPER = "com.example.voice_2_note_ai/whisper"
    }
}
