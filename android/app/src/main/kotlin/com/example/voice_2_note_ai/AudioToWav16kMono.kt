package com.example.voice_2_note_ai

import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.FileOutputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * m4a/mp3/wav vb. ses dosyasını Whisper NDK'nın beklediği 16 kHz mono 16-bit PCM WAV'a çevirir.
 * FFmpeg kullanmaz; [MediaExtractor] + [MediaCodec] ile çözümler.
 */
object AudioToWav16kMono {
    private const val TARGET_SAMPLE_RATE = 16000
    private const val TIMEOUT_US = 10_000L

    fun convert(inputPath: String, outputPath: String): Boolean {
        val extractor = MediaExtractor()
        try {
            extractor.setDataSource(inputPath)
        } catch (_: IOException) {
            return false
        }

        val trackIndex = (0 until extractor.trackCount).firstOrNull { i ->
            val mime = extractor.getTrackFormat(i).getString(MediaFormat.KEY_MIME)
            mime?.startsWith("audio/") == true
        } ?: run {
            extractor.release()
            return false
        }

        extractor.selectTrack(trackIndex)
        val inputFormat = extractor.getTrackFormat(trackIndex)
        val mime = inputFormat.getString(MediaFormat.KEY_MIME) ?: run {
            extractor.release()
            return false
        }

        val decoder = try {
            MediaCodec.createDecoderByType(mime)
        } catch (_: Exception) {
            extractor.release()
            return false
        }

        try {
            decoder.configure(inputFormat, null, null, 0)
            decoder.start()
        } catch (_: Exception) {
            decoder.release()
            extractor.release()
            return false
        }

        val pcmSamples = ArrayList<Short>(65536)
        var sourceSampleRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var sourceChannels = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

        val bufferInfo = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false
        var guard = 0

        try {
            while (!outputDone && guard++ < 500_000) {
                if (!inputDone) {
                    val inIndex = decoder.dequeueInputBuffer(TIMEOUT_US)
                    if (inIndex >= 0) {
                        val buffer = decoder.getInputBuffer(inIndex)!!
                        val sampleSize = extractor.readSampleData(buffer, 0)
                        if (sampleSize < 0) {
                            decoder.queueInputBuffer(
                                inIndex,
                                0,
                                0,
                                0L,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                            )
                            inputDone = true
                        } else {
                            val t = extractor.sampleTime
                            decoder.queueInputBuffer(inIndex, 0, sampleSize, t, 0)
                            extractor.advance()
                        }
                    }
                }

                val outIndex = decoder.dequeueOutputBuffer(bufferInfo, TIMEOUT_US)
                when {
                    outIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> { /* no-op */ }
                    outIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        val fmt = decoder.outputFormat
                        sourceSampleRate = fmt.getInteger(MediaFormat.KEY_SAMPLE_RATE)
                        sourceChannels = fmt.getInteger(MediaFormat.KEY_CHANNEL_COUNT)
                    }
                    outIndex >= 0 -> {
                        val outBuf = decoder.getOutputBuffer(outIndex)!!
                        val fmt = decoder.outputFormat
                        val enc = if (fmt.containsKey(MediaFormat.KEY_PCM_ENCODING)) {
                            fmt.getInteger(MediaFormat.KEY_PCM_ENCODING)
                        } else {
                            AudioFormat.ENCODING_PCM_16BIT
                        }

                        when (enc) {
                            AudioFormat.ENCODING_PCM_FLOAT -> {
                                val fb = outBuf.order(ByteOrder.nativeOrder()).asFloatBuffer()
                                while (fb.hasRemaining()) {
                                    val f = fb.get()
                                    val s = (f * 32767f).toInt().coerceIn(
                                        Short.MIN_VALUE.toInt(),
                                        Short.MAX_VALUE.toInt(),
                                    )
                                    pcmSamples.add(s.toShort())
                                }
                            }
                            else -> {
                                val sb = outBuf.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
                                while (sb.hasRemaining()) {
                                    pcmSamples.add(sb.get())
                                }
                            }
                        }

                        val eos = bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                        decoder.releaseOutputBuffer(outIndex, false)
                        if (eos) {
                            outputDone = true
                        }
                    }
                }
            }
        } catch (_: Exception) {
            decoder.stop()
            decoder.release()
            extractor.release()
            return false
        }

        decoder.stop()
        decoder.release()
        extractor.release()

        if (pcmSamples.isEmpty()) {
            return false
        }

        val rem = pcmSamples.size % sourceChannels.coerceAtLeast(1)
        repeat(rem) {
            if (pcmSamples.isNotEmpty()) pcmSamples.removeAt(pcmSamples.lastIndex)
        }

        val mono = downmixToMono(pcmSamples.toShortArray(), sourceChannels)
        val resampled = resampleLinear(mono, sourceSampleRate, TARGET_SAMPLE_RATE)

        return try {
            writeWavFile(outputPath, resampled, TARGET_SAMPLE_RATE, 1, 16)
            true
        } catch (_: IOException) {
            false
        }
    }

    private fun downmixToMono(interleaved: ShortArray, channels: Int): ShortArray {
        if (channels <= 1) return interleaved
        val frames = interleaved.size / channels
        val out = ShortArray(frames)
        var i = 0
        for (f in 0 until frames) {
            var sum = 0
            for (c in 0 until channels) {
                sum += interleaved[i++].toInt()
            }
            out[f] = (sum / channels).toShort()
        }
        return out
    }

    private fun resampleLinear(mono: ShortArray, fromRate: Int, toRate: Int): ShortArray {
        if (fromRate == toRate) return mono
        if (fromRate <= 0 || toRate <= 0) return mono
        val outLen = (mono.size.toLong() * toRate / fromRate).toInt().coerceAtLeast(1)
        val out = ShortArray(outLen)
        for (i in 0 until outLen) {
            val srcPos = i * fromRate.toDouble() / toRate
            val idx = srcPos.toInt()
            val frac = srcPos - idx
            if (idx + 1 < mono.size) {
                val a = mono[idx].toInt()
                val b = mono[idx + 1].toInt()
                out[i] = (a + (b - a) * frac).toInt().toShort()
            } else {
                out[i] = mono[idx.coerceAtMost(mono.lastIndex)]
            }
        }
        return out
    }

    @Throws(IOException::class)
    private fun writeWavFile(
        path: String,
        pcm: ShortArray,
        sampleRate: Int,
        channels: Int,
        bitsPerSample: Int,
    ) {
        val dataLen = pcm.size * (bitsPerSample / 8)
        val header = ByteArray(44)
        val totalDataLen = 36 + dataLen
        val byteRate = sampleRate * channels * bitsPerSample / 8
        val blockAlign = (channels * bitsPerSample / 8).toShort()

        header[0] = 'R'.code.toByte()
        header[1] = 'I'.code.toByte()
        header[2] = 'F'.code.toByte()
        header[3] = 'F'.code.toByte()
        writeLe32(header, 4, totalDataLen)
        header[8] = 'W'.code.toByte()
        header[9] = 'A'.code.toByte()
        header[10] = 'V'.code.toByte()
        header[11] = 'E'.code.toByte()
        header[12] = 'f'.code.toByte()
        header[13] = 'm'.code.toByte()
        header[14] = 't'.code.toByte()
        header[15] = ' '.code.toByte()
        writeLe32(header, 16, 16)
        writeLe16(header, 20, 1)
        writeLe16(header, 22, channels.toShort())
        writeLe32(header, 24, sampleRate)
        writeLe32(header, 28, byteRate)
        writeLe16(header, 32, blockAlign)
        writeLe16(header, 34, bitsPerSample.toShort())
        header[36] = 'd'.code.toByte()
        header[37] = 'a'.code.toByte()
        header[38] = 't'.code.toByte()
        header[39] = 'a'.code.toByte()
        writeLe32(header, 40, dataLen)

        FileOutputStream(path).use { fos ->
            fos.write(header)
            val bb = ByteBuffer.allocate(pcm.size * 2).order(ByteOrder.LITTLE_ENDIAN)
            for (s in pcm) {
                bb.putShort(s)
            }
            fos.write(bb.array())
        }
    }

    private fun writeLe32(arr: ByteArray, offset: Int, v: Int) {
        arr[offset] = (v and 0xff).toByte()
        arr[offset + 1] = (v shr 8 and 0xff).toByte()
        arr[offset + 2] = (v shr 16 and 0xff).toByte()
        arr[offset + 3] = (v shr 24 and 0xff).toByte()
    }

    private fun writeLe16(arr: ByteArray, offset: Int, v: Short) {
        arr[offset] = (v.toInt() and 0xff).toByte()
        arr[offset + 1] = (v.toInt() shr 8 and 0xff).toByte()
    }
}
