import 'package:flutter/material.dart';
import 'package:voice_2_note_ai/app/splash_screen.dart';
import 'package:voice_2_note_ai/app/theme.dart';

/// Uygulama kök widget'ı. MaterialApp, tema ve ilk ekran (splash/tanıtım).
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice2 Note AI',
      theme: appTheme,
      home: const SplashScreen(),
    );
  }
}
