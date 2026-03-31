package com.example.voice_2_note_ai

/**
 * whisper.cpp JNI köprüsü bu kütüphaneye bağlanacak.
 * Şimdilik NDK derlemesinin yüklendiğini doğrulayan [ping] vardır.
 */
object WhisperNative {
    init {
        System.loadLibrary("voice2note_whisper")
    }

    @JvmStatic
    external fun ping(): String

    @JvmStatic
    external fun transcribe(
        modelPath: String?,
        audioPath: String?,
    ): String
}
