// android/app/src/main/kotlin/.../JBVisualizerManager.kt
//
// Wraps android.media.audiofx.Visualizer and pushes processed spectrum data
// to Flutter over an EventChannel. Sits next to your existing BassBoost /
// Equalizer / Reverb / Virtualizer / Spatializer managers and uses the same
// sessionId.
//
// Wire-up in MainActivity.kt (see bottom of this file for the exact snippet).

package com.jbmusic.app // ← change to your actual package

import android.media.audiofx.Visualizer
import androidx.annotation.NonNull
import io.flutter.plugin.common.EventChannel
import kotlin.math.hypot
import kotlin.math.log10
import kotlin.math.max

class JBVisualizerManager {

    private var visualizer: Visualizer? = null
    private var eventSink: EventChannel.EventSink? = null
    private var currentSessionId: Int = -1

    companion object {
        // Number of bars sent to Flutter. 32 is plenty for a smooth UI bar
        // graph without flooding the channel at 60fps.
        private const val BAR_COUNT = 32
    }

    // ── EventChannel plumbing ───────────────────────────────────────────────

    fun attachEventChannel(channel: EventChannel) {
        channel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(args: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
            }

            override fun onCancel(args: Any?) {
                eventSink = null
            }
        })
    }

    // ── Lifecycle ────────────────────────────────────────────────────────────

    /**
     * Call this whenever the active audio session id changes (i.e. from the
     * same place you already re-apply BassBoost/Equalizer/etc — your
     * DspRestore-equivalent path). Safe to call repeatedly with the same id.
     */
    fun attachToSession(sessionId: Int) {
        if (sessionId == currentSessionId && visualizer != null) return
        release()

        try {
            visualizer = Visualizer(sessionId).apply {
                captureSize = Visualizer.getCaptureSizeRange()[1]
                setDataCaptureListener(
                    object : Visualizer.OnDataCaptureListener {
                        override fun onFftDataCapture(
                            visualizer: Visualizer?,
                            fft: ByteArray?,
                            samplingRate: Int
                        ) {
                            if (fft == null) return
                            val bars = fftToBars(fft, BAR_COUNT)
                            eventSink?.success(bars)
                        }

                        override fun onWaveFormDataCapture(
                            visualizer: Visualizer?,
                            waveform: ByteArray?,
                            samplingRate: Int
                        ) {
                            // Not used — we drive the UI off FFT data only.
                            // Kept here in case you want a waveform mode later.
                        }
                    },
                    Visualizer.getMaxCaptureRate() / 2, // throttle a bit below max; plenty smooth, less binder traffic
                    false, // don't need raw waveform callbacks
                    true   // do need FFT callbacks
                )
                enabled = true
            }
            currentSessionId = sessionId
        } catch (e: Exception) {
            // Visualizer can throw if the session id is invalid/stale
            // (e.g. briefly during a track transition). Fail quietly —
            // the next attachToSession call will retry.
            visualizer = null
            currentSessionId = -1
        }
    }

    fun setEnabled(enabled: Boolean) {
        visualizer?.enabled = enabled
    }

    fun release() {
        try {
            visualizer?.enabled = false
            visualizer?.release()
        } catch (_: Exception) {
            // ignore — already released or never initialized
        }
        visualizer = null
        currentSessionId = -1
    }

    // ── FFT → bars ───────────────────────────────────────────────────────────

    /**
     * Android's Visualizer FFT output is packed as:
     *   fft[0]            = Re(0)  (DC component)
     *   fft[1]            = Re(n/2) (Nyquist)
     *   fft[2k], fft[2k+1] = Re(k), Im(k)  for k = 1..n/2-1
     *
     * We compute magnitude per bin, convert to dB, bucket the bins into
     * `barCount` groups using a log scale (so bass isn't squashed into the
     * first couple of bars), and normalize to 0.0–1.0 for the UI.
     */
    private fun fftToBars(fft: ByteArray, barCount: Int): List<Double> {
        val n = fft.size
        val numBins = n / 2 // usable complex bins

        val magnitudes = DoubleArray(numBins)
        magnitudes[0] = Math.abs(fft[0].toInt()).toDouble() // DC
        for (k in 1 until numBins) {
            val re = fft[2 * k].toInt().toDouble()
            val im = if (2 * k + 1 < n) fft[2 * k + 1].toInt().toDouble() else 0.0
            magnitudes[k] = hypot(re, im)
        }

        // Log-scale bin grouping: low bars cover few bins (bass detail),
        // high bars cover many bins (treble is naturally noisier/denser).
        val bars = DoubleArray(barCount)
        val logMax = log10(numBins.toDouble())
        var prevEdge = 0
        for (b in 0 until barCount) {
            val frac = (b + 1).toDouble() / barCount
            val edge = max(prevEdge + 1, (Math.pow(10.0, frac * logMax)).toInt())
                .coerceAtMost(numBins)
            var sum = 0.0
            var count = 0
            for (i in prevEdge until edge) {
                sum += magnitudes[i]
                count++
            }
            val avg = if (count > 0) sum / count else 0.0
            // Convert to a rough dB scale, then normalize. 255.0 ≈ max raw
            // magnitude headroom for 8-bit FFT output; tune to taste.
            val db = 20 * log10(avg.coerceAtLeast(1.0))
            bars[b] = (db / 48.0).coerceIn(0.0, 1.0) // 48dB ≈ practical dynamic range
            prevEdge = edge
        }

        return bars.toList()
    }
}

/*
─────────────────────────────────────────────────────────────────────────────
WIRE-UP IN MainActivity.kt
─────────────────────────────────────────────────────────────────────────────

class MainActivity: FlutterActivity() {

    private val visualizerManager = JBVisualizerManager()

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ... your existing MethodChannel setup for BassBoost/Equalizer/etc ...

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, "jb_music/fft")
            .let { visualizerManager.attachEventChannel(it) }
    }

    // Call this from the SAME place you already restore BassBoost/Equalizer
    // for a new session id (your existing DSP-restore path):
    //
    //   visualizerManager.attachToSession(sessionId)
    //
    // And from onDestroy() / when playback service tears down:
    //
    //   visualizerManager.release()
}
─────────────────────────────────────────────────────────────────────────────
*/