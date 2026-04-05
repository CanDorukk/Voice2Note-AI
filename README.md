# Voice2 Note AI

Flutter tabanlı ses kaydı → çevrimdışı Whisper transkript → özet (TextRank) → SQLite notlar.

## Özellikler (özet)

- **Tema:** Sistem, açık veya koyu; tercih cihazda saklanır ve ana ekranlarda menüden değiştirilebilir.
- **Notlar:** Liste; transkript/özet araması; detayda **düzenleme** (kaydet), kopyalama, ses oynatma; silmeden sonra SnackBar ile **geri al**.
- **Kayıt / dosya:** Mikrofon kaydı veya dosya seçicide **yalnızca ses** (ör. m4a, wav); Android’de gerekirse `AudioToWav16kMono` ile 16 kHz mono PCM WAV’a dönüştürülür. Arka planda aynı işlem (`audio_to_note_pipeline.dart`) transkript + özet + veritabanı. Bekleyen satırlar `pending_processing_provider.dart`.
- **Gezinme:** Ana `MaterialPageRoute` geçişleri `lib/app/app_navigation.dart` içinde toplanır.
- **PDF:** Önizleme/yazdırma (`printing`) ve dosyaya kaydetme; paylaşım ekranında transkript/özet/PDF paylaşımı.
- **Hakkında:** Uygulama sürümü ve `showLicensePage` ile lisanslar; ilk açılış tanıtım ekranında sürüm satırı.

## Gereksinimler

- Flutter SDK (pubspec içindeki sürüm aralığı)
- **Android:** NDK ile `whisper.cpp` native modülü; ayrıntı için `android/app/src/main/cpp/third_party/README.md`

## Model dosyası (Whisper)

**Android:** İlk açılış **Splash** ekranında model yoksa **Hugging Face’den indirme** (~60 MB, HTTPS; `INTERNET` izni). İsterseniz modeli elle de kurabilirsiniz: `assets/models/ggml-base-q5_1.bin` dosyasını [ggerganov/whisper.cpp](https://huggingface.co/ggerganov/whisper.cpp/tree/main) üzerinden indirip `assets/models/` altına koyun. `*.bin` repoda yok (`.gitignore`); CI’da boş dosya oluşturulur. **Yerelde 0 bayt placeholder ile transkript çalışmaz** — gerçek dosya veya uygulama içi indirme gerekir.

## Çalıştırma

```bash
flutter pub get
flutter run
```

## Test

```bash
flutter test
flutter analyze
```

Push ve pull request’lerde GitHub Actions aynı komutları çalıştırır (`.github/workflows/flutter_ci.yml`). Tam **APK/NDK** derlemesi CI’da yoktur; yerelde `flutter build apk` ile deneyebilirsiniz.

## Yapılacaklar (ileride)

1. **Model:** İsteğe bağlı `small` ggml quantize veya uygulama içi model seçimi.
2. **İçe aktarma:** iOS veya ek biçimler için dönüştürme / net hata mesajları (Android’de m4a vb. MediaCodec ile).
3. **Türkçe:** Ek normalizasyon (birleşik/ayrık yazım, kullanıcı sözlüğü) ve arama eş anlamlılığı.

## Platform notu

Çevrimdışı Whisper şu an **Android** hedefi için yapılandırılmıştır; iOS tarafı bu aşamada öncelikli değildir.
