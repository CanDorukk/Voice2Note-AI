package com.example.voice_2_note_ai

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val audioExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_AUDIO,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "convertAudioToWhisperWav" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<*, *>
                    val inputPath = args?.get("inputPath") as? String
                    val outputPath = args?.get("outputPath") as? String
                    if (inputPath.isNullOrBlank() || outputPath.isNullOrBlank()) {
                        result.error("BAD_ARGS", "inputPath veya outputPath eksik", null)
                        return@setMethodCallHandler
                    }
                    audioExecutor.execute {
                        val ok = try {
                            AudioToWav16kMono.convert(inputPath, outputPath)
                        } catch (e: Throwable) {
                            android.util.Log.e(
                                "Voice2NoteAudio",
                                "convertAudioToWhisperWav",
                                e,
                            )
                            false
                        }
                        runOnUiThread {
                            result.success(ok)
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        audioExecutor.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL_AUDIO = "com.example.voice_2_note_ai/audio"
    }
}
