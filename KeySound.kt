package com.example.gasi_candle_ai

import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioTrack
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin
import kotlin.random.Random

/**
 * ওয়েলকাম স্ক্রিনের কিবোর্ড ট্যাপ সাউন্ড।
 * কোনো অডিও ফাইল বা প্যাকেজ লাগে না: চারটা ছোট (প্রায় 38ms) ক্লিক সাউন্ড কোড দিয়েই বানানো হয়,
 * প্রতিবার আলাদা একটা বাজে, তাই একঘেয়ে লাগে না।
 */
object KeySound {
    private const val RATE = 44100
    private const val VARIANTS = 4
    private var tracks: List<AudioTrack> = emptyList()
    private var next = 0

    /** MainActivity.configureFlutterEngine-এর ভেতর থেকে ডাকা হয়। */
    fun register(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, "gasi/keysound")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "tap" -> {
                        tap()
                        result.success(null)
                    }
                    "release" -> {
                        release()
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun makeClick(variant: Int): ShortArray {
        val rnd = Random(variant + 11)
        val n = RATE * 38 / 1000
        val out = ShortArray(n)
        val thockHz = 150.0 + variant * 22.0 // নিচু "থক" আওয়াজ
        val tickHz = 2400.0 + variant * 260.0 // ওপরের "টিক" আওয়াজ
        var lp = 0.0
        for (i in 0 until n) {
            val t = i.toDouble() / RATE
            val noise = rnd.nextDouble() * 2.0 - 1.0
            lp += 0.35 * (noise - lp) // নরম করা নয়েজ
            val click = lp * exp(-t * 220.0)
            val tick = sin(2.0 * PI * tickHz * t) * exp(-t * 420.0) * 0.45
            val thock = sin(2.0 * PI * thockHz * t) * exp(-t * 90.0) * 0.8
            val attack = if (i < 40) i / 40.0 else 1.0 // শুরুতে "পপ" শব্দ এড়াতে
            val v = (click * 0.9 + tick + thock) * 0.55 * attack
            out[i] = (v * Short.MAX_VALUE).toInt().coerceIn(-32767, 32767).toShort()
        }
        return out
    }

    private fun build(): List<AudioTrack> {
        return (0 until VARIANTS).map { variant ->
            val pcm = makeClick(variant)
            val track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(RATE)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(pcm.size * 2)
                .setTransferMode(AudioTrack.MODE_STATIC)
                .build()
            track.write(pcm, 0, pcm.size)
            track.setVolume(0.7f)
            track
        }
    }

    @Synchronized
    fun tap() {
        try {
            if (tracks.isEmpty()) tracks = build()
            val t = tracks[next]
            next = (next + 1) % tracks.size
            t.stop()
            t.reloadStaticData()
            t.play()
        } catch (_: Throwable) {
            // সাউন্ড না বাজলেও অ্যাপ যেন কখনো ক্র্যাশ না করে।
        }
    }

    @Synchronized
    fun release() {
        try {
            tracks.forEach { it.release() }
        } catch (_: Throwable) {
        }
        tracks = emptyList()
        next = 0
    }
}
