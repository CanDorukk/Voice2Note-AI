import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:voice_2_note_ai/app/about_section_header.dart';
import 'package:voice_2_note_ai/app/theme_tokens.dart';
import 'package:voice_2_note_ai/features/notes/user_search_synonyms_provider.dart';
import 'package:voice_2_note_ai/services/turkish_search_synonym_prefs.dart';

/// Hakkında: not araması için isteğe bağlı eş anlamlı satırları (`kelime=kanonik`).
class TurkishSearchSynonymsSection extends ConsumerStatefulWidget {
  const TurkishSearchSynonymsSection({super.key});

  @override
  ConsumerState<TurkishSearchSynonymsSection> createState() =>
      _TurkishSearchSynonymsSectionState();
}

class _TurkishSearchSynonymsSectionState
    extends ConsumerState<TurkishSearchSynonymsSection> {
  final TextEditingController _ctrl = TextEditingController();
  bool _loading = true;
  bool _savedHint = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await TurkishSearchSynonymPrefs.loadRaw();
    if (!mounted) return;
    setState(() {
      _ctrl.text = raw;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await TurkishSearchSynonymPrefs.saveRaw(_ctrl.text);
    ref.invalidate(userSearchSynonymsBundleProvider);
    if (!mounted) return;
    setState(() => _savedHint = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _savedHint = false);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_loading) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cs.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Arama sözlüğü yükleniyor…',
              style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AboutSectionHeader('Not araması (eş anlamlı)'),
        Text(
          'Her satırda bir eşleme: aranacak kelime = nottaki kanonik kelime. '
          'Yerleşik gruplar (doktor/hekim, araba/otomobil vb.) zaten vardır; buradan ekleyebilirsin. '
          '# ile başlayan satırlar yorum sayılır.',
          style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _ctrl,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'örnek:\nmuayene=doktor\nşirket=firma',
          ),
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            FilledButton.tonal(
              onPressed: _save,
              child: const Text('Sözlüğü kaydet'),
            ),
            if (_savedHint) ...[
              Icon(Icons.check_circle_rounded, size: 18, color: cs.primary),
              Text(
                'Kaydedildi',
                style: textTheme.labelMedium?.copyWith(color: cs.primary),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
