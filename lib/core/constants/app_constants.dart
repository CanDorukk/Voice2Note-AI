/// Uygulama genel sabitleri.
class AppConstants {
  AppConstants._();

  /// SharedPreferences: tanıtım ekranı bir kez gösterildi mi?
  static const String introSeenKey = 'intro_seen';

  /// SharedPreferences: `WhisperGgmlModel.name` (`tiny` | `base` | `small`).
  static const String whisperGgmlModelKey = 'whisper_ggml_model';
}
