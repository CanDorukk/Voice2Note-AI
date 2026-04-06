package com.example.voice_2_note_ai

import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder

/**
 * m4a/mp3/wav vb. ses dosyasını Whisper NDK'nın beklediği 16 kHz mono 16-bit PCM WAV'a çevirir.
 * FFmpeg kullanmaz; [MediaExtractor] + [MediaCodec] ile çözümler.
 *
 * Uzun kayıtlarda OOM önlemek için çözülen PCM tamponda tutulmaz; önce kaynak hızda mono raw
 * dosyaya yazılır, sonra dosyadan parçalar halinde 16 kHz'e örneklenir.
 */
object AudioToWav16kMono {
    private const val TARGET_SAMPLE_RATE = 16000
    private const val TIMEOUT_US = 10_000L
    private const val RESAMPLE_BATCH_OUT = 8192

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

        var sourceSampleRate = inputFormat.getInteger(MediaFormat.KEY_SAMPLE_RATE)
        var sourceChannels = inputFormat.getInteger(MediaFormat.KEY_CHANNEL_COUNT)

        val outParent = File(outputPath).parentFile
        val tempMono = File.createTempFile("v2n_mono_", ".raw", outParent)

        val bufferInfo = MediaCodec.BufferInfo()
        var inputDone = false
        var outputDone = false
        var guard = 0

        var pending = ShortArray(0)

        try {
            FileOutputStream(tempMono).use { monoOut ->
                val ch = monoOut.channel
                val bbLE = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)

                fun writeMonoShort(s: Short) {
                    bbLE.clear()
                    bbLE.putShort(s)
                    bbLE.flip()
                    ch.write(bbLE)
                }

                fun appendAndFlushMono(interleaved: ShortArray, channels: Int) {
                    if (channels <= 0) return
                    val merged = if (pending.isEmpty()) {
                        interleaved
                    } else {
                        pending + interleaved
                    }
                    val frames = merged.size / channels
                    val complete = frames * channels
                    var offset = 0
                    if (channels == 1) {
                        for (i in 0 until complete) {
                            writeMonoShort(merged[i])
                        }
                    } else {
                        repeat(frames) {
                            var sum = 0
                            repeat(channels) {
                                sum += merged[offset++].toInt()
                            }
                            writeMonoShort((sum / channels).toShort())
                        }
                    }
                    pending = if (complete < merged.size) {
                        merged.copyOfRange(complete, merged.size)
                    } else {
                        ShortArray(0)
                    }
                }

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

                            val chunk: ShortArray = when (enc) {
                                AudioFormat.ENCODING_PCM_FLOAT -> {
                                    val fb = outBuf.order(ByteOrder.nativeOrder()).asFloatBuffer()
                                    val n = fb.remaining()
                                    val arr = ShortArray(n)
                                    var i = 0
                                    while (fb.hasRemaining()) {
                                        val f = fb.get()
                                        val s = (f * 32767f).toInt().coerceIn(
                                            Short.MIN_VALUE.toInt(),
                                            Short.MAX_VALUE.toInt(),
                                        )
                                        arr[i++] = s.toShort()
                                    }
                                    arr
                                }
                                else -> {
                                    val sb = outBuf.order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
                                    val n = sb.remaining()
                                    val arr = ShortArray(n)
                                    var i = 0
                                    while (sb.hasRemaining()) {
                                        arr[i++] = sb.get()
                                    }
                                    arr
                                }
                            }

                            appendAndFlushMono(chunk, sourceChannels)

                            val eos = bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                            decoder.releaseOutputBuffer(outIndex, false)
                            if (eos) {
                                outputDone = true
                            }
                        }
                    }
                }
            }
        } catch (_: Exception) {
            decoder.stop()
            decoder.release()
            extractor.release()
            tempMono.delete()
            return false
        }

        decoder.stop()
        decoder.release()
        extractor.release()

        val ch = sourceChannels.coerceAtLeast(1)
        if (pending.isNotEmpty()) {
            val rem = pending.size % ch
            if (rem != 0) {
                pending = pending.copyOfRange(0, pending.size - rem)
            }
            if (pending.isNotEmpty()) {
                FileOutputStream(tempMono, true).use { monoOut ->
                    val c = monoOut.channel
                    val bbLE = ByteBuffer.allocate(4).order(ByteOrder.LITTLE_ENDIAN)
                    var offset = 0
                    val frames = pending.size / ch
                    repeat(frames) {
                        var sum = 0
                        repeat(ch) {
                            sum += pending[offset++].toInt()
                        }
                        val s = (sum / ch).toShort()
                        bbLE.clear()
                        bbLE.putShort(s)
                        bbLE.flip()
                        c.write(bbLE)
                    }
                }
            }
        }

        if (!tempMono.exists() || tempMono.length() < 2L) {
            tempMono.delete()
            return false
        }

        val ok = try {
            resampleRawMonoFileToWav(tempMono, outputPath, sourceSampleRate, TARGET_SAMPLE_RATE)
        } catch (_: Exception) {
            false
        } finally {
            tempMono.delete()
        }
        return ok
    }

    private fun resampleRawMonoFileToWav(
        rawFile: File,
        wavPath: String,
        fromRate: Int,
        toRate: Int,
    ): Boolean {
        if (fromRate <= 0 || toRate <= 0) return false
        val inSamples = (rawFile.length() / 2).toInt()
        if (inSamples <= 0) return false

        val outSamples = (inSamples.toLong() * toRate / fromRate).toInt().coerceAtLeast(1)

        val rafIn = RandomAccessFile(rawFile, "r")
        val dataLen = outSamples * 2
        val header = ByteArray(44)
        val totalDataLen = 36 + dataLen
        val byteRate = toRate * 1 * 16 / 8
        val blockAlign = (1 * 16 / 8).toShort()

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
        writeLe16(header, 22, 1)
        writeLe32(header, 24, toRate)
        writeLe32(header, 28, byteRate)
        writeLe16(header, 32, blockAlign)
        writeLe16(header, 34, 16)

        header[36] = 'd'.code.toByte()
        header[37] = 'a'.code.toByte()
        header[38] = 't'.code.toByte()
        header[39] = 'a'.code.toByte()
        writeLe32(header, 40, dataLen)

        try {
            FileOutputStream(wavPath).use { fos ->
                fos.write(header)
                val outCh = fos.channel
                val bbOut = ByteBuffer.allocate(RESAMPLE_BATCH_OUT * 2)
                    .order(ByteOrder.LITTLE_ENDIAN)

                if (fromRate == toRate) {
                    // Kopyala (16-bit LE)
                    rafIn.channel.position(0)
                    val buf = ByteBuffer.allocate(65536)
                    while (rafIn.filePointer < rafIn.length()) {
                        buf.clear()
                        val n = rafIn.channel.read(buf)
                        if (n <= 0) break
                        buf.flip()
                        outCh.write(buf)
                    }
                } else {
                    var outPos = 0
                    while (outPos < outSamples) {
                        val batchEnd = (outPos + RESAMPLE_BATCH_OUT).coerceAtMost(outSamples)
                        val srcPosFirst = outPos * fromRate.toDouble() / toRate
                        val srcPosLast = (batchEnd - 1) * fromRate.toDouble() / toRate
                        var srcStart = srcPosFirst.toInt()
                        var srcEndExclusive = srcPosLast.toInt() + 2
                        srcStart = srcStart.coerceIn(0, inSamples - 1)
                        srcEndExclusive = srcEndExclusive.coerceAtMost(inSamples)
                        if (srcEndExclusive <= srcStart) {
                            srcEndExclusive = (srcStart + 1).coerceAtMost(inSamples)
                        }

                        val chunkLen = srcEndExclusive - srcStart
                        val chunk = ShortArray(chunkLen)
                        rafIn.seek(srcStart.toLong() * 2)
                        val bbChunk = ByteBuffer.allocate(chunkLen * 2).order(ByteOrder.LITTLE_ENDIAN)
                        rafIn.readFully(bbChunk.array(), 0, chunkLen * 2)
                        bbChunk.asShortBuffer().get(chunk)

                        bbOut.clear()
                        var i = outPos
                        while (i < batchEnd) {
                            val srcPos = i * fromRate.toDouble() / toRate
                            val idx = (srcPos.toInt() - srcStart).coerceIn(0, chunk.lastIndex)
                            val frac = srcPos - srcPos.toInt()
                            val i0 = idx.coerceIn(0, chunk.lastIndex)
                            val i1 = (idx + 1).coerceIn(0, chunk.lastIndex)
                            val s0 = chunk[i0].toInt()
                            val s1 = chunk[i1].toInt()
                            val v = (s0 + (s1 - s0) * frac).toInt()
                                .coerceIn(Short.MIN_VALUE.toInt(), Short.MAX_VALUE.toInt())
                                .toShort()
                            bbOut.putShort(v)
                            i++
                        }
                        bbOut.flip()
                        outCh.write(bbOut)
                        outPos = batchEnd
                    }
                }
            }
        } finally {
            rafIn.close()
        }
        return true
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
