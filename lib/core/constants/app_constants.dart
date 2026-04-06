/// Uygulama genel sabitleri.
class AppConstants {
  AppConstants._();

  /// SharedPreferences: tanıtım ekranı bir kez gösterildi mi?
  static const String introSeenKey = 'intro_seen';

  /// SharedPreferences: `WhisperGgmlModel.name` (`tiny` | `base` | `small`).
  static const String whisperGgmlModelKey = 'whisper_ggml_model';

  /// Örn. `http://192.168.1.10:8787` — boşsa transkript yalnızca cihazda (NDK).
  static const String remoteTranscribeBaseUrlKey = 'remote_transcribe_base_url';

  /// İsteğe bağlı; PC sunucusunda `V2N_API_KEY` ile eşleşmeli.
  static const String remoteTranscribeApiKeyKey = 'remote_transcribe_api_key';
}
