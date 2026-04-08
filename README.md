# Voice2 Note AI

**Sürüm 1.0** — Ses kaydından not üreten Flutter uygulaması. Paket sürümü [`pubspec.yaml`](pubspec.yaml) içinde (`0.1.0`); özellik seti ve mimari bu **1.0** çizgisindedir.

## Bu uygulama ne yapar?

Voice2 Note AI ile **ses kaydı** veya **dosyadan içe aktarma** ile konuşmanızı metne dökersiniz; metin **yerelde not** olarak saklanır, üzerinde **özet** (TextRank) alabilir, **arayabilir**, **PDF** üretebilir ve **paylaşabilirsiniz**. Odak **Android**’dir.

Transkript (konuşmayı yazıya çevirme) **telefonda çalışmaz**: uygulama sesi kendi ağınızdaki bir bilgisayara veya VPS’e **HTTP ile gönderir**; orada **Whisper** (bu repoda [faster-whisper](https://github.com/SYSTRAN/faster-whisper) ile) çalışır. Yani **Whisper, mobil uygulama içinde değil — sunucu tarafında, genelde kendi PC’nizde yerel bir API olarak** çalışır.

## Teknoloji yığını

| Katman | Teknoloji |
|--------|-----------|
| **İstemci** | [Flutter](https://flutter.dev/) (Dart), Material 3, [Riverpod](https://riverpod.dev/) |
| **Yerel veri** | [SQLite](https://pub.dev/packages/sqflite) (`sqflite`), [shared_preferences](https://pub.dev/packages/shared_preferences) |
| **Ses** | [record](https://pub.dev/packages/record), [just_audio](https://pub.dev/packages/just_audio), dosya içe aktarma |
| **Ağ** | Transkript için `http` ile `POST …/transcribe` (multipart ses dosyası) |
| **Özet** | İstemcide TextRank tabanlı özet ([`lib/services/summary_service.dart`](lib/services/summary_service.dart)) |
| **Dışa aktarım** | [pdf](https://pub.dev/packages/pdf), [printing](https://pub.dev/packages/printing), [share_plus](https://pub.dev/packages/share_plus) |
| **Transkript sunucusu (bu repo)** | [FastAPI](https://fastapi.tiangolo.com/) + **faster-whisper** + **ffmpeg** (sesi 16 kHz mono WAV’a normalize eder) |

## Whisper mimarisi (v1)

```
[Android telefon]  --Wi‑Fi / ağ-->  [PC veya VPS: Python sunucu]
       |                                    |
   kayıt / dosya                      ffmpeg + faster-whisper
       |                                    |
       +-------- POST /transcribe ---------+
       +<------- JSON { "text": "..." } ---+
```

- Uygulama paketinde **Whisper modeli veya ggml dosyası yoktur**; model **sunucu makinesinde** indirilir ve çalıştırılır.
- Varsayılan kurulum: bilgisayarınızda `server/pc_whisper_server` ile **yerel HTTP API** (`uvicorn`, örn. port `8787`). Telefon ile **aynı Wi‑Fi** (veya erişilebilir IP) gerekir.
- İsteğe bağlı: aynı kodu **VPS**’e koyup HTTPS ile kullanmak (adresi uygulamada **Hakkında**’dan güncellersiniz).

Ortam değişkenleri (model boyutu, CUDA/CPU, beam, VAD, dil) ve güvenlik için: **[docs/pc_whisper_sunucu.md](docs/pc_whisper_sunucu.md)**  
Sunucu klasörü özeti: **[server/pc_whisper_server/README.md](server/pc_whisper_server/README.md)**

> **Not:** `cursor/whisper_setup_guide.md` içindeki whisper.cpp / ggml yolu, bu v1 akışından **ayrı** bir deneysel/ileri kurulum rehberidir; güncel transkript yolu **sunucu tabanlı faster-whisper**’dır.

## Özellikler (özet)

- Tema (sistem / açık / koyu), not listesi, transkript ve özet üzerinden arama (Türkçe eş anlamlı desteği)
- Not detayında düzenleme, kopyalama, ses oynatma, PDF ve paylaşım
- **Hakkında** ekranında transkript sunucusu taban URL ve isteğe bağlı API anahtarı
- Android odaklı; iOS bu repoda tam kapsamlı değildir

## Gereksinimler

- **Uygulama:** Flutter SDK (`pubspec.yaml` içindeki Dart SDK aralığı)
- **Transkript:** Ağ üzerinden erişilebilir **PC Whisper sunucusu** — Python 3.10+, ffmpeg (PATH), isteğe bağlı NVIDIA + CUDA (`V2N_DEVICE=cuda`)

## Uygulamayı çalıştırma

```bash
git clone <bu-depo-url>
cd voice_2_note_ai
flutter pub get
flutter run
```

Önce sunucuyu çalıştırıp uygulamada **Hakkında** bölümünden taban adresi kaydedin (örn. `http://192.168.1.10:8787`).

## Sunucuyu çalıştırma (özet)

```powershell
cd server\pc_whisper_server
python -m venv .venv
.\.venv\Scripts\Activate.ps1   # Linux/macOS: source .venv/bin/activate
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8787
```

Ayrıntılı adımlar, güvenlik duvarı ve `V2N_*` ortam değişkenleri: **[docs/pc_whisper_sunucu.md](docs/pc_whisper_sunucu.md)**.

## Geliştirme ve kalite

```bash
flutter analyze
flutter test
```

CI: [`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml)

## Lisans

[LICENSE](LICENSE) dosyasına bakın.
