# PC’de Whisper sunucusu ve uygulama bağlantısı

Flutter uygulaması **telefonda Whisper modeli içermez**; transkript yalnızca kayıtlı **HTTP sunucusu** üzerinden yapılır (kendi bilgisayarın veya VPS). Bu depoda hazır **FastAPI + faster-whisper** sunucusu ve uygulama tarafında **multipart ile ses gönderimi** vardır.

## Ne gerekir?

- **Windows / Linux / macOS** üzerinde **Python 3.10+**
- **ffmpeg** yüklü ve **PATH**’te olmalı (sunucu tüm ses biçimlerini 16 kHz mono WAV’a çevirir). Windows: [ffmpeg.org](https://ffmpeg.org/download.html) veya `winget install ffmpeg`.
- İsteğe bağlı: **NVIDIA GPU** + güncel sürücü (CUDA varsa transkript çok hızlanır; yoksa CPU ile de çalışır)
- Telefon ve bilgisayarın **aynı Wi‑Fi** ağında olması (veya tünel / VPN ile erişim)
- Uygulama tarafında **İnternet** izni (zaten manifestte var)

## 1) Bilgisayarda sunucuyu kur

**Önemli:** Sanal ortam (` .venv `) proje içindeki `server\pc_whisper_server` klasöründe oluşur. `Activate.ps1`’i çalıştırmadan önce **mutlaka o klasöre geç** (`C:\Users\Can` gibi kullanıcı klasöründe bu dosya yoktur).

Proje kökünden örnek:

```powershell
cd "F:\Projelerim\Voice2Note AI\voice_2_note_ai\server\pc_whisper_server"
python -m venv .venv
```

Yol sende farklıysa Explorer’da `pc_whisper_server` klasörüne gidip adres çubuğundan kopyalayabilirsin.

Windows PowerShell (aynı pencerede, **hâlâ `pc_whisper_server` içindeyken**):

```powershell
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

`Activate.ps1` bulunamıyorsa genelde iki sebep vardır: yanlış klasördesin veya üstteki `python -m venv .venv` hiç çalışmadı.

İlk kez PowerShell ile script çalıştırıyorsan ve “running scripts is disabled” benzeri bir hata alırsan (bir kerelik):

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Sonra `Activate.ps1`’i tekrar dene.

Linux / macOS:

```bash
source .venv/bin/activate
pip install -r requirements.txt
```

İlk çalıştırmada **faster-whisper** seçilen modeli otomatik indirir (`V2N_MODEL`, varsayılan `small`).

## 2) Sunucuyu başlat

```bash
uvicorn main:app --host 0.0.0.0 --port 8787
```

- `--host 0.0.0.0` telefonun aynı ağdan bilgisayara erişmesi içindir (yalnızca `127.0.0.1` dinlersen telefon bağlanamaz).

Tarayıcıdan test: `http://127.0.0.1:8787/health` — `ok` yanında model, istenen cihaz, `beam_size`, `vad_filter`, dil özeti döner (API anahtarı yok).

### İsteğe bağlı ortam değişkenleri

| Değişken | Anlam |
|---------|--------|
| `V2N_MODEL` | `tiny` → `base` → `small` → `medium` → `large-v2` / `large-v3` (faster-whisper destekli isimler). Varsayılan: **`small`**. Daha büyük model: genelde daha iyi transkript, daha fazla RAM/VRAM ve süre. |
| `V2N_DEVICE` | `cpu` (varsayılan) veya `cuda` — tam CUDA/cuBLAS kurulu değilse `cpu` kullanın; `cublas64_12.dll` vb. hatalarda sunucu otomatik CPU’ya düşer. |
| `V2N_BEAM_SIZE` | Çözüm araması genişliği (1–20, varsayılan **5**). Artırmak kaliteyi bir miktar iyileştirebilir, süreyi uzatır. |
| `V2N_VAD_FILTER` | `true`/`1` veya `false`/`0` (varsayılan **true**). Açıkken sessiz/gürültülü kısımlar daha iyi ayrılır; çok kısa veya kesik kayıtlarda denemek için `false` denenebilir. |
| `V2N_LANGUAGE` | Varsayılan **`tr`** (Türkçe kayıtlar). Karışık dil veya test için `auto` yazılabilir (otomatik dil seçimi). |
| `V2N_API_KEY` | Örn. `gizli-bir-kelime` — doluysa uygulamada da aynı anahtar girilmeli |

### Model boyutu — kabaca beklenti

Tam ölçüm donanıma bağlıdır; yönlendirme için:

| Model | Kalite (kabaca) | Not |
|-------|-----------------|-----|
| `tiny` / `base` | Hızlı, daha çok hata | Zayıf PC veya hızlı deneme |
| `small` | Dengeli varsayılan | Çoğu kurulum için iyi başlangıç |
| `medium` | Daha iyi | Daha fazla RAM/VRAM, daha uzun süre |
| `large-v2` / `large-v3` | En iyi (faster-whisper ile) | Güçlü GPU veya sabırlı CPU; ilk indirme büyük |

**CUDA:** `V2N_DEVICE=cuda` ile GPU kullanımı; yoksa `cpu` ve `int8` ile çalışır (dokümantasyon: üstteki tablo).

Örnek (PowerShell):

```powershell
$env:V2N_MODEL="small"
$env:V2N_API_KEY="benim-gizli-anahtarim"
uvicorn main:app --host 0.0.0.0 --port 8787
```

## 3) Bilgisayarın yerel IP adresini bul

- **Windows:** `ipconfig` → “IPv4 Address” (ör. `192.168.1.105`)
- Telefon ve PC **aynı router** ağında olmalı.

Sunucu adresin örnek: `http://192.168.1.105:8787`

## 4) Windows güvenlik duvarı

İlk bağlantıda Windows “erişime izin ver” sorarsa **özel ağlar** için izin ver. Açılmazsa Gelişmiş Güvenlik Duvarı’nda **8787 TCP** giriş kuralı ekle.

## 5) Uygulamada adresi kaydet

1. Uygulamayı aç → **Hakkında**.
2. **Transkript sunucusu** (kök adres) alanına yaz: `http://192.168.1.105:8787` (sonunda `/` olmasın zorunluluğu yok; uygulama `/transcribe` yolunu ekler).
3. API anahtarı kullandıysan **API anahtarı** alanına aynı değeri yaz.
4. **Sunucu ayarını kaydet**’e bas.

Bundan sonra transkript **bu adrese** gönderilir. Adres boşsa uygulama transkript başlatmaz (Hakkında’dan sunucu adresini kaydetmen gerekir). Mobil uygulama model çalıştırmaz.

### Uzaktan transkript notları

- Uygulama `POST .../transcribe` ile ses dosyasını **multipart** `file` alanında yollar; yanıt `{"text":"..."}` JSON olmalıdır (bu repodaki `main.py` ile uyumludur).
- Çok uzun kayıtlar için istemci tarafında zaman aşımı ses süresine göre uzatılır; yine de PC’nin uyku moduna geçmemesi iyi olur.

## 6) Komut satırından hızlı test

Ses dosyan `ornek.wav` iken (curl veya PowerShell `Invoke-RestMethod`):

```bash
curl -s -X POST "http://127.0.0.1:8787/transcribe" -F "file=@ornek.wav"
```

JSON içinde `text` alanı görünmeli.

## İleride gerçek sunucuya (VPS) taşımak

1. Aynı `server/pc_whisper_server` kodunu VPS’e kopyala, `venv` + `pip install` + `uvicorn` (veya systemd / Docker).
2. **HTTPS** kullan (Let’s Encrypt). Uygulamadaki adresi `https://api.alanadin.com` gibi güncelle; anahtarı da aynı tut.
3. API uç noktası ve `POST /transcribe` + `{"text"}` formatı **aynı kaldığı sürece** uygulama tarafında büyük kod değişikliği gerekmez; sadece **kayıtlı taban URL**’yi değiştirirsin.

## Sorun giderme

| Sorun | Olası neden |
|-------|----------------|
| Telefon bağlanamıyor | Farklı Wi‑Fi, yanlış IP, güvenlik duvarı, sunucu kapalı |
| `Connection refused` | `uvicorn` `--host 0.0.0.0` ile çalışmıyor |
| `500` + `cublas64_12.dll` / CUDA | GPU sürücü veya cuBLAS eksik; güncel `main.py` varsayılan **CPU** kullanır — `uvicorn`’u yeniden başlat |
| Çok yavaş | CPU kullanılıyor; mümkünse NVIDIA + tam CUDA kurulumu ve `V2N_DEVICE=cuda` veya `V2N_MODEL=tiny` (kalite düşer) |
| İlk kurulum uzun | Sunucuda (PC) model ilk kez indiriliyor olabilir; `small` birkaç yüz MB |

## Güvenlik

- Yerel ağda bile **API anahtarı** kullanmak iyi bir alışkanlıktır.
- Wi‑Fi misafir ağı veya halka açık ağda HTTP ile şifresiz dinleme yapma; prod’da **HTTPS + güçlü anahtar**.
