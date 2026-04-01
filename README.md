# Voice2 Note AI

Flutter tabanlı ses kaydı → çevrimdışı Whisper transkript → özet (TextRank) → SQLite notlar.

## Gereksinimler

- Flutter SDK (pubspec içindeki sürüm aralığı)
- **Android:** NDK ile `whisper.cpp` native modülü; ayrıntı için `android/app/src/main/cpp/third_party/README.md`

## Model dosyası (Whisper)

`assets/models/ggml-tiny-q5_1.bin` dosyasını [Hugging Face `ggerganov/whisper.cpp`](https://huggingface.co/ggerganov/whisper.cpp/tree/main) üzerinden indirip `assets/models/` altına koyun. `*.bin` dosyaları `.gitignore` içindedir; repoda bulunmaz.

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

## Platform notu

Çevrimdışı Whisper şu an **Android** hedefi için yapılandırılmıştır; iOS tarafı bu aşamada öncelikli değildir.
