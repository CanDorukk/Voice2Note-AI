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
                    // Sonraki adım: whisper.cpp JNI ile gerçek transkript.
                    result.success(
                        "[Whisper stub] MethodChannel çalışıyor. " +
                            "modelPath=${modelPath ?: "(null)"}, " +
                            "audioPath=${audioPath ?: "(null)"}",
                    )
                }
                else -> result.notImplemented()
            }
        }
    }

    companion object {
        private const val CHANNEL_WHISPER = "com.example.voice_2_note_ai/whisper"
    }
}
