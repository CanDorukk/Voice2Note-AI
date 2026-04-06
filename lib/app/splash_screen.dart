import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_2_note_ai/app/app_navigation.dart';
import 'package:voice_2_note_ai/app/theme_tokens.dart';
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
    const horizontal = AppSpacing.lg;
    const vertical = AppSpacing.md;
    const pad = EdgeInsets.symmetric(horizontal: horizontal, vertical: vertical);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final minScrollHeight = constraints.maxHeight - vertical * 2;
            return SingleChildScrollView(
              padding: pad,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minScrollHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.sm),
                        Center(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(AppRadii.xl),
                              border: Border.all(
                                color: cs.outlineVariant.withOpacity(0.45),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: CircleAvatar(
                                radius: 48,
                                backgroundColor: cs.primaryContainer,
                                child: Icon(
                                  Icons.graphic_eq_rounded,
                                  size: 48,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Voice2 Note AI',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          kIsWeb || !Platform.isAndroid
                              ? 'Kayıtlarınızı metne dökün, kısa özetler alın.'
                              : 'Kayıtlarınızı metne dökün, kısa özetler alın.\n'
                                  'Transkript bilgisayarınızdaki sunucu üzerinden çalışır; '
                                  'adresi Hakkında bölümünden girin.',
                          style: textTheme.bodyLarge?.copyWith(
                            color: cs.onSurfaceVariant,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (_versionLine != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            _versionLine!,
                            style: textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: FilledButton.icon(
                        onPressed: () => _onStart(context),
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Başla'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                      ),
                    ),
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
