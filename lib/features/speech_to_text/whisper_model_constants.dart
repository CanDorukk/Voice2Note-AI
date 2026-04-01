/// ggml-tiny.bin için beklenen minimum boyut (kırpılmış/bozuk dosyayı yakalamak için).
/// Resmi tiny model ~75 MB civarıdır; 50 MB altını geçersiz sayıyoruz.
const int kWhisperGgmlTinyMinBytes = 50 * 1024 * 1024;
