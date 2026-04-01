import 'package:flutter/material.dart';

/// Açık tema.
ThemeData get appTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
  );
}

/// Koyu tema (sistem karanlık modunda kullanılır).
ThemeData get appDarkTheme {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.deepPurple,
      brightness: Brightness.dark,
    ),
  );
}
