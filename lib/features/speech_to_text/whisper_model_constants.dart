/// `ggml-tiny-q5_1.bin` için beklenen minimum boyut (kırpılmış/bozuk dosyayı yakalamak için).
/// Resmi quantize tiny ~31 MB; 25 MB altını geçersiz sayıyoruz.
const int kWhisperGgmlTinyQ5MinBytes = 25 * 1024 * 1024;
