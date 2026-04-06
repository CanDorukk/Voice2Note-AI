import 'package:shared_preferences/shared_preferences.dart';

import 'package:voice_2_note_ai/core/constants/app_constants.dart';

/// PC / VPS üzerindeki transkript HTTP API kök adresi (boş = transkript yapılamaz).
class RemoteTranscribeSettings {
  RemoteTranscribeSettings._();

  static Future<String?> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final u = prefs.getString(AppConstants.remoteTranscribeBaseUrlKey)?.trim();
    if (u == null || u.isEmpty) {
      return null;
    }
    return u;
  }

  static Future<void> setBaseUrl(String? url) async {
    final prefs = await SharedPreferences.getInstance();
    final t = url?.trim();
    if (t == null || t.isEmpty) {
      await prefs.remove(AppConstants.remoteTranscribeBaseUrlKey);
    } else {
      await prefs.setString(AppConstants.remoteTranscribeBaseUrlKey, t);
    }
  }

  static Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final k = prefs.getString(AppConstants.remoteTranscribeApiKeyKey)?.trim();
    if (k == null || k.isEmpty) {
      return null;
    }
    return k;
  }

  static Future<void> setApiKey(String? key) async {
    final prefs = await SharedPreferences.getInstance();
    final t = key?.trim();
    if (t == null || t.isEmpty) {
      await prefs.remove(AppConstants.remoteTranscribeApiKeyKey);
    } else {
      await prefs.setString(AppConstants.remoteTranscribeApiKeyKey, t);
    }
  }

  static Future<bool> isRemoteEnabled() async {
    final u = await getBaseUrl();
    return u != null && u.isNotEmpty;
  }
}
