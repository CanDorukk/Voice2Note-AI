import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_2_note_ai/app/app_navigation.dart';
import 'package:voice_2_note_ai/core/constants/app_constants.dart';

/// Tanıtım ekranı. Transkript sunucu tabanlı; adres Hakkında’dan girilir.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _versionLine;

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLine = '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _onStart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.introSeenKey, true);
    if (!context.mounted) return;
    AppNavigation.pushNotesReplace(context);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 8),
                    Center(
                      child: CircleAvatar(
                        radius: 44,
                        backgroundColor: cs.primaryContainer,
                        child: Icon(
                          Icons.graphic_eq_rounded,
                          size: 44,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Voice2 Note AI',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      kIsWeb || !Platform.isAndroid
                          ? 'Kayıtlarınızı metne dökün, kısa özetler alın.'
                          : 'Kayıtlarınızı metne dökün, kısa özetler alın.\n'
                              'Transkript bilgisayarınızdaki sunucu üzerinden çalışır; '
                              'adresi Hakkında bölümünden girin.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_versionLine != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _versionLine!,
                        style: textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    SizedBox(
                      height: (constraints.maxHeight * 0.12).clamp(32.0, 100.0),
                    ),
                    FilledButton.icon(
                      onPressed: () => _onStart(context),
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Başla'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
