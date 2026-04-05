import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:voice_2_note_ai/features/speech_to_text/whisper_model_service.dart';

/// Android’de Whisper modeli yoksa indirme ekranı; hazırsa [child] gösterilir.
class WhisperModelBootstrap extends StatefulWidget {
  const WhisperModelBootstrap({super.key, required this.child});

  final Widget child;

  @override
  State<WhisperModelBootstrap> createState() => _WhisperModelBootstrapState();
}

class _WhisperModelBootstrapState extends State<WhisperModelBootstrap> {
  bool _checking = true;
  bool _ready = false;
  bool _downloading = false;
  int _received = 0;
  int? _total;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    if (kIsWeb || !Platform.isAndroid) {
      setState(() {
        _ready = true;
        _checking = false;
      });
      return;
    }
    final path = await WhisperModelService.instance.ensureReady();
    if (!mounted) return;
    setState(() {
      _ready = path != null && path.isNotEmpty;
      _checking = false;
    });
  }

  Future<void> _download() async {
    setState(() {
      _error = null;
      _downloading = true;
      _received = 0;
      _total = null;
    });
    final ok = await WhisperModelService.instance.downloadGgmlBaseQ5FromNetwork(
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
        _error = 'İndirme başarısız. İnternet bağlantısını kontrol edin.';
      });
      return;
    }
    final path = await WhisperModelService.instance.ensureReady();
    setState(() {
      _downloading = false;
      _ready = path != null && path.isNotEmpty;
      if (!_ready) {
        _error = 'Model doğrulanamadı.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_ready) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final mb = _total != null && _total! > 0
        ? _received / _total!
        : null;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 32),
              Icon(
                Icons.download_rounded,
                size: 56,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Whisper modeli gerekli',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Çevrimdışı konuşmayı metne çevirmek için ggml-base-q5_1.bin '
                'dosyası (~60 MB) bir kez indirilmeli. İsterseniz README’deki gibi '
                'elle de assets/models/ içine koyabilirsiniz.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Spacer(),
              if (_downloading) ...[
                if (mb != null)
                  LinearProgressIndicator(value: mb)
                else
                  const LinearProgressIndicator(),
                const SizedBox(height: 8),
                Text(
                  _total != null && _total! > 0
                      ? '${(_received / (1024 * 1024)).toStringAsFixed(1)} / '
                          '${(_total! / (1024 * 1024)).toStringAsFixed(1)} MB'
                      : 'İndiriliyor…',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 24),
              ],
              FilledButton.icon(
                onPressed: _downloading ? null : _download,
                icon: const Icon(Icons.cloud_download_rounded),
                label: Text(_downloading ? 'İndiriliyor…' : 'Modeli indir'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _downloading
                    ? null
                    : () => setState(() => _ready = true),
                child: const Text('Şimdilik atla (transkript çalışmaz)'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
