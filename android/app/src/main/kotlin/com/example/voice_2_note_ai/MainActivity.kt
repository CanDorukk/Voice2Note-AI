package com.example.voice_2_note_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val whisperExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_WHISPER,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "warmup" -> {
                    val modelPath = call.arguments as? String
                    whisperExecutor.execute {
                        val nativeResult = try {
                            WhisperNative.warmup(modelPath)
                        } catch (e: Throwable) {
                            e.message ?: "warmup hata"
                        }
                        runOnUiThread {
                            result.success(nativeResult)
                        }
                    }
                }
                "transcribe" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<*, *>
                    val modelPath = args?.get("modelPath") as? String
                    val audioPath = args?.get("audioPath") as? String
                    whisperExecutor.execute {
                        val nativeResult = try {
                            WhisperNative.transcribe(
                                modelPath = modelPath,
                                audioPath = audioPath,
                            )
                        } catch (e: Throwable) {
                            "Transkript alınamadı: ${e.message ?: "bilinmeyen hata"}"
                        }
                        runOnUiThread {
                            result.success(nativeResult)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        whisperExecutor.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL_WHISPER = "com.example.voice_2_note_ai/whisper"
    }
}
