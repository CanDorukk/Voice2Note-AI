/// Uygulama genel sabitleri.
class AppConstants {
  AppConstants._();

  /// SharedPreferences: tanıtım ekranı bir kez gösterildi mi?
  static const String introSeenKey = 'intro_seen';

  /// Örn. `http://192.168.1.10:8787` — transkript sunucusu.
  static const String remoteTranscribeBaseUrlKey = 'remote_transcribe_base_url';

  /// İsteğe bağlı; PC sunucusunda `V2N_API_KEY` ile eşleşmeli.
  static const String remoteTranscribeApiKeyKey = 'remote_transcribe_api_key';

  /// Not araması: kullanıcı eş anlamlı satırları (çok satırlı metin).
  static const String turkishSearchUserSynonymsRawKey =
      'turkish_search_user_synonyms_raw';
}
