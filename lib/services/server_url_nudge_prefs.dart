import 'package:shared_preferences/shared_preferences.dart';

import 'package:voice_2_note_ai/core/constants/app_constants.dart';

class ServerUrlNudgePrefs {
  ServerUrlNudgePrefs._();

  static Future<bool> shouldShowSetupNudge() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.serverTranscribeSetupNudgeSeenKey) != true;
  }

  static Future<void> markSetupNudgeSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.serverTranscribeSetupNudgeSeenKey, true);
  }
}
