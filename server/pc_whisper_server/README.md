# PC Whisper HTTP API

Kurulum ve uygulama bağlantısı için ana dokümantasyon:

**[docs/pc_whisper_sunucu.md](../../docs/pc_whisper_sunucu.md)**

Özet (önce `server\pc_whisper_server` klasörüne `cd` et):

```powershell
cd "…\voice_2_note_ai\server\pc_whisper_server"
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8787
```

`Activate.ps1` yok hatası: yanlış dizindesin veya `venv` oluşturulmadı.
