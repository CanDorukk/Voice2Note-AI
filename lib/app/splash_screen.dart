import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_2_note_ai/app/app_navigation.dart';
import 'package:voice_2_note_ai/core/constants/app_constants.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_ggml_model.dart';
import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';
import 'package:voice_2_note_ai/services/remote_transcribe_settings.dart';

/// Tanıtım ekranı. Transkript için öncelik internet + kayıtlı PC sunucusu; çevrimdışı paket isteğe bağlı.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String? _versionLine;
  WhisperGgmlModel _kind = WhisperGgmlModel.small;
  bool _modelChecking = true;
  bool _modelReady = false;
  bool _remoteUrlConfigured = false;
  bool _downloading = false;
  int _received = 0;
  int? _total;
  String? _downloadError;

  @override
  void initState() {
    super.initState();
    _loadVersion();
    _initModelState();
  }

  Future<void> _initModelState() async {
    if (kIsWeb || !Platform.isAndroid) {
      if (!mounted) return;
      setState(() {
        _modelReady = true;
        _modelChecking = false;
      });
      return;
    }
    final kind = await WhisperModelService.instance.getSelectedModel();
    final remoteOn = await RemoteTranscribeSettings.isRemoteEnabled();
    if (!mounted) return;
    setState(() {
      _kind = kind;
      _remoteUrlConfigured = remoteOn;
    });
    await _refreshModelReady();
  }

  Future<void> _onModelKindChanged(WhisperGgmlModel next) async {
    if (_downloading) return;
    await WhisperModelService.instance.setSelectedModel(next);
    if (!mounted) return;
    setState(() {
      _kind = next;
      _downloadError = null;
    });
    await _refreshModelReady();
  }

  Future<void> _refreshModelReady() async {
    if (kIsWeb || !Platform.isAndroid) return;
    setState(() => _modelChecking = true);
    final remoteOn = await RemoteTranscribeSettings.isRemoteEnabled();
    if (!mounted) return;
    if (remoteOn) {
      setState(() {
        _remoteUrlConfigured = true;
        _modelChecking = false;
      });
      final pathRemote = await WhisperModelService.instance.ensureReady();
      if (!mounted) return;
      setState(() {
        _modelReady = pathRemote != null && pathRemote.isNotEmpty;
      });
      return;
    }
    final path = await WhisperModelService.instance.ensureReady();
    if (!mounted) return;
    setState(() {
      _remoteUrlConfigured = false;
      _modelReady = path != null && path.isNotEmpty;
      _modelChecking = false;
    });
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _versionLine = '${info.version} (${info.buildNumber})';
    });
  }

  Future<void> _downloadModel() async {
    setState(() {
      _downloadError = null;
      _downloading = true;
      _received = 0;
      _total = null;
    });
    final ok = await WhisperModelService.instance.downloadSelectedModelFromNetwork(
      onProgress: (received, total) {
        if (!mounted) return;
        setState(() {
          _received = received;
          _total = total;
        });
      },
    );
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _downloading = false;
        _downloadError =
            'İndirilemedi. İnternet bağlantınızı kontrol edip yeniden deneyin.';
      });
      return;
    }
    final path = await WhisperModelService.instance.ensureReady();
    if (!mounted) return;
    setState(() {
      _downloading = false;
      _modelReady = path != null && path.isNotEmpty;
      if (!_modelReady) {
        _downloadError = 'Paket doğrulanamadı. Yeniden indirmeyi deneyin.';
      }
    });
  }

  Future<void> _onStart(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.introSeenKey, true);
    if (!context.mounted) return;
    AppNavigation.pushNotesReplace(context);
  }

  /// Çevrimdışı paket indirme alanı (yerel ggml yokken; PC sunucusu olsa da isteğe bağlı).
  bool get _needsModelUi =>
      !kIsWeb && Platform.isAndroid && !_modelChecking && !_modelReady;

  bool get _canPressStart {
    if (_downloading || _modelChecking) return false;
    return true;
  }

  IconData get _splashModelStatusIcon {
    if (_modelReady) {
      return Icons.verified_rounded;
    }
    if (_remoteUrlConfigured) {
      return Icons.cloud_done_rounded;
    }
    return Icons.model_training_rounded;
  }

  Color _splashModelStatusColor(ColorScheme cs) {
    if (_modelReady || _remoteUrlConfigured) {
      return cs.primary;
    }
    return cs.secondary;
  }

  String get _splashModelStatusTitle {
    if (_modelReady && _remoteUrlConfigured) {
      return 'PC sunucusu + çevrimdışı paket hazır';
    }
    if (_modelReady) {
      return 'Çevrimdışı paket hazır';
    }
    if (_remoteUrlConfigured) {
      return 'PC sunucusu kayıtlı';
    }
    return 'Çevrimdışı paket (isteğe bağlı)';
  }

  String get _splashModelHelpText {
    if (_modelReady) {
      return 'Kayıt veya dosya içe aktarma ile çevrimdışı transkript kullanılabilir.';
    }
    if (_remoteUrlConfigured) {
      return 'Transkript için Hakkında’da kayıtlı adres kullanılır (internet gerekir). '
          'İsterseniz aşağıdan çevrimdışı paketi de indirebilirsiniz '
          '(yaklaşık ${_kind.approxDownloadMegabytes} MB).';
    }
    return 'İnternet + PC sunucusu (Hakkında’dan) veya bu paketle transkript. '
        'Paket yaklaşık ${_kind.approxDownloadMegabytes} MB; mümkünse Wi‑Fi kullanın.';
  }

  double? get _progressFraction {
    final t = _total;
    if (t == null || t <= 0) return null;
    return (_received / t).clamp(0.0, 1.0);
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
                        'Kayıtlarınızı metne dökün, kısa özetler alın.\n'
                        'Özet cihazda; transkript için internet ve isteğe bağlı PC sunucusu veya '
                        'çevrimdışı paket kullanılır.',
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
                      const SizedBox(height: 28),
                      if (_modelChecking && Platform.isAndroid && !kIsWeb)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: cs.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Hazırlık yapılıyor…',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (!kIsWeb && Platform.isAndroid) ...[
                        Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          color: cs.surfaceContainerHighest.withAlpha(
                            // opacity → .a geçişi yerel eski Flutter’da .a yok; CI ile uyum için.
                            // ignore: deprecated_member_use
                            (cs.surfaceContainerHighest.opacity *
                                    255.0 *
                                    0.85)
                                .round()
                                .clamp(0, 255),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: cs.outlineVariant.withAlpha(
                                // ignore: deprecated_member_use
                                (cs.outlineVariant.opacity *
                                        255.0 *
                                        0.45)
                                    .round()
                                    .clamp(0, 255),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _splashModelStatusIcon,
                                      color: _splashModelStatusColor(cs),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _splashModelStatusTitle,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                WhisperGgmlModelSegmentedButton(
                                  selected: _kind,
                                  enabled: !_downloading,
                                  onChanged: _onModelKindChanged,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  _splashModelHelpText,
                                  style: textTheme.bodySmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    height: 1.4,
                                  ),
                                ),
                                if (_needsModelUi) ...[
                                  const SizedBox(height: 14),
                                  if (_downloadError != null)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Text(
                                        _downloadError!,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: cs.error,
                                        ),
                                      ),
                                    ),
                                  if (_downloading) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        minHeight: 8,
                                        value: _progressFraction,
                                        backgroundColor:
                                            cs.surfaceContainerHigh,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _total != null && _total! > 0
                                          ? '${(_received / (1024 * 1024)).toStringAsFixed(1)} / '
                                              '${(_total! / (1024 * 1024)).toStringAsFixed(1)} MB'
                                          : 'İndiriliyor…',
                                      style: textTheme.labelSmall?.copyWith(
                                        color: cs.onSurfaceVariant,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                  if (!_downloading) ...[
                                    FilledButton.tonalIcon(
                                      onPressed: _downloadModel,
                                      icon: const Icon(Icons.cloud_download_rounded),
                                      label: const Text('Ses paketini indir'),
                                      style: FilledButton.styleFrom(
                                        minimumSize: const Size.fromHeight(48),
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      SizedBox(
                        height: (constraints.maxHeight * 0.08).clamp(24.0, 80.0),
                      ),
                      FilledButton.icon(
                        onPressed: _canPressStart
                            ? () => _onStart(context)
                            : null,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Başla'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 52),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      if (_downloading && Platform.isAndroid && !kIsWeb) ...[
                        const SizedBox(height: 10),
                        Text(
                          'İndirme sürerken Başla geçici olarak kapalıdır.',
                          style: textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
