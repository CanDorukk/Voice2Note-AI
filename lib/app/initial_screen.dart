import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_2_note_ai/core/constants/app_constants.dart';
import 'package:voice_2_note_ai/app/splash_screen.dart';
import 'package:voice_2_note_ai/features/notes/notes_screen.dart';

/// İlk açılışta tanıtımı gösterir, sonraki açılışlarda doğrudan notlar ekranına gider.
class InitialScreen extends StatelessWidget {
  const InitialScreen({super.key});

  Future<bool> _hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.introSeenKey) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenIntro(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final seen = snapshot.data ?? false;
        return seen ? const NotesScreen() : const SplashScreen();
      },
    );
  }
}
