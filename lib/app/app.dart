import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:voice_2_note_ai/app/initial_screen.dart';
import 'package:voice_2_note_ai/app/theme.dart';
import 'package:voice_2_note_ai/app/theme_mode_provider.dart';

/// Uygulama kök widget'ı. MaterialApp, tema ve ilk ekran (ilk açılışta tanıtım, sonra notlar).
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeModeProvider);
    final themeMode = themeAsync.value ?? ThemeMode.system;

    return MaterialApp(
      title: 'Voice2 Note AI',
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: themeMode,
      home: const InitialScreen(),
    );
  }
}
