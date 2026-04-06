/// `ggml-tiny-q5_1.bin` — mobilde en hızlı; ~25–30 MB.
const int kWhisperGgmlTinyQ5MinBytes = 22 * 1024 * 1024;

/// `ggml-base-q5_1.bin` için beklenen minimum boyut (kırpılmış/bozuk dosyayı yakalamak için).
/// Quantize base ~57 MB; 50 MB altını geçersiz sayıyoruz.
const int kWhisperGgmlBaseQ5MinBytes = 50 * 1024 * 1024;

/// `ggml-small-q5_1.bin` için minimum boyut (~190 MB civarı; kısmi indirmeyi ele).
const int kWhisperGgmlSmallQ5MinBytes = 160 * 1024 * 1024;
