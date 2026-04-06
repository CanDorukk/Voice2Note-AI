package com.example.voice_2_note_ai

import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {
    private val contentExecutor = Executors.newSingleThreadExecutor()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_CONTENT,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "copyContentUriToFile" -> {
                    @Suppress("UNCHECKED_CAST")
                    val args = call.arguments as? Map<*, *>
                    val uriStr = args?.get("uri") as? String
                    val destPath = args?.get("destPath") as? String
                    if (uriStr.isNullOrBlank() || destPath.isNullOrBlank()) {
                        result.error("BAD_ARGS", "uri veya destPath eksik", null)
                        return@setMethodCallHandler
                    }
                    contentExecutor.execute {
                        val ok = try {
                            val uri = Uri.parse(uriStr)
                            val dest = File(destPath)
                            dest.parentFile?.mkdirs()
                            contentResolver.openInputStream(uri)?.use { input ->
                                dest.outputStream().use { output ->
                                    input.copyTo(output)
                                }
                            }
                            dest.exists() && dest.length() > 0L
                        } catch (_: Throwable) {
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
        contentExecutor.shutdown()
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL_CONTENT = "com.example.voice_2_note_ai/content"
    }
}
