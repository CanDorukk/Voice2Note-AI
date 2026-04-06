# Voice2 Note AI

**Sürüm:** `0.1.0` (kaynak: [`pubspec.yaml`](pubspec.yaml) — yayın öncesi sürüm numarası oradan takip edilir.)

Flutter ile yazılmış bir **ses notu** uygulaması: mikrofon veya dosyadan ses → **transkript** (kendi ağınızdaki HTTP sunucusu üzerinden) → **özet** (TextRank) → **SQLite** ile yerel notlar. Uygulama paketinde **Whisper / ggml modeli yoktur**; transkript tamamen sunucu tarafında yapılır.

## Mimari (özet)

| Bileşen | Rol |
|--------|-----|
| **Flutter uygulaması** | Kayıt, not listesi, arama, PDF, tema; transkript için `POST …/transcribe` ile ses dosyası gönderir. |
| **PC / VPS API** | Bu repodaki [`server/pc_whisper_server`](server/pc_whisper_server) örneği: `ffmpeg` ile sesi normalize eder, **faster-whisper** ile metin üretir. |

Ayrıntılı kurulum ve güvenlik için: **[docs/pc_whisper_sunucu.md](docs/pc_whisper_sunucu.md)**  
Sunucu klasörü kısa özeti: **[server/pc_whisper_server/README.md](server/pc_whisper_server/README.md)**

## Özellikler

- Tema (sistem / açık / koyu), not listesi, transkript ve özet üzerinden arama
- Not detayında düzenleme, kopyalama, ses oynatma, PDF ve paylaşım
- **Hakkında** ekranında transkript sunucusu adresi ve isteğe bağlı API anahtarı
- Android’de odak; iOS bu repoda tam kapsamlı değildir

## Gereksinimler

- **Flutter:** `pubspec.yaml` içindeki SDK aralığı (`>=3.4.3 <4.0.0`)
- **Transkript:** Telefon ve sunucunun aynı Wi‑Fi veya erişilebilir ağda olması; sunucuda **Python 3.10+**, **ffmpeg** (PATH), isteğe bağlı NVIDIA/CUDA

## Uygulamayı çalıştırma

```bash
git clone <bu-depo-url>
cd voice_2_note_ai
flutter pub get
flutter run
```

Önce sunucuyu açıp uygulamada **Hakkında** bölümünden taban URL’yi kaydetmeniz gerekir (örn. `http://192.168.1.10:8787`).

## Sunucuyu çalıştırma (özet)

```powershell
cd server\pc_whisper_server
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8787
```

Tam adımlar, güvenlik duvarı ve ortam değişkenleri için **[docs/pc_whisper_sunucu.md](docs/pc_whisper_sunucu.md)** dosyasına bakın.

## Geliştirme ve kalite

```bash
flutter analyze
flutter test
```

CI: [`.github/workflows/flutter_ci.yml`](.github/workflows/flutter_ci.yml)

## Lisans

Depo kökündeki [LICENSE](LICENSE) dosyasına bakın.
