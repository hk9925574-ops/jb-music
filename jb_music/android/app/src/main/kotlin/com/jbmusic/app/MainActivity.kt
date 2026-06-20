package com.jbmusic.app
import android.media.AudioManager
import android.media.Spatializer
import android.os.Build
import android.media.audiofx.BassBoost
import android.media.audiofx.EnvironmentalReverb
import android.media.audiofx.Virtualizer
import android.media.audiofx.Equalizer
import android.media.audiofx.LoudnessEnhancer
import android.os.Bundle
import android.util.Log
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {

    private val CHANNEL = "jb_music/dsp"

    private var virtualizer: Virtualizer? = null
    private var bassBoost: BassBoost? = null
    private var reverb: EnvironmentalReverb? = null
    private var spatializer: Spatializer? = null
    private var equalizer: Equalizer? = null
    private var loudnessEnhancer: LoudnessEnhancer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)

    Log.d(
        "JB_DSP",
        "MAIN ACTIVITY CREATED"
    )

    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

        val audioManager =
            getSystemService(
                AUDIO_SERVICE
            ) as AudioManager

        spatializer =
            audioManager.spatializer

        Log.d(
            "JB_DSP",
            "SPATIALIZER AVAILABLE = ${spatializer?.isAvailable}"
        )

        Log.d(
            "JB_DSP",
            "SPATIALIZER ENABLED = ${spatializer?.isEnabled}"
        )
    }
}

    private fun applyReverbPreset(
        preset: String
    ) {

        if (reverb == null) return

        when (preset) {

            "room" -> {
                reverb?.decayTime = 1000
                reverb?.reverbLevel = (-500).toShort()
            }

            "hall" -> {
                reverb?.decayTime = 1800
                reverb?.reverbLevel = (-300).toShort()
            }

            "concert" -> {
                reverb?.decayTime = 2500
                reverb?.reverbLevel = (-150).toShort()
            }

            "arena" -> {
                reverb?.decayTime = 3200
                reverb?.reverbLevel = 0
            }

            "stadium" -> {
                reverb?.decayTime = 4500
                reverb?.reverbLevel = 200
            }

            "cathedral" -> {
                reverb?.decayTime = 6000
                reverb?.reverbLevel = 400
            }

            "cave" -> {
                reverb?.decayTime = 7000
                reverb?.reverbLevel = 600
            }
        }
    }

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {

        super.configureFlutterEngine(flutterEngine)

        Log.d(
            "JB_DSP",
            "METHOD CHANNEL REGISTERED"
        )

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "setPan" -> {
                    result.success(true)
                }

                // ===== VIRTUALIZER =====
                "enableSpatialAudio" -> {

                    val enabled =
                        call.argument<Boolean>("enabled") ?: false

                    val sessionId =
                        call.argument<Int>("sessionId") ?: 0

                    try {

                        if (enabled) {

                            if (
                                Build.VERSION.SDK_INT >=
                                Build.VERSION_CODES.TIRAMISU &&
                                spatializer?.isAvailable == true
                            ) {

                                Log.d(
                                    "JB_DSP",
                                    "Using Android Spatializer"
                                )

                            } else {

                                virtualizer?.release()

                                virtualizer = Virtualizer(
                                    1000,
                                    sessionId
                                )

                                if (virtualizer?.strengthSupported == true) {
                                    virtualizer?.setStrength(
                                        1000.toShort()
                                    )
                                }

                                virtualizer?.enabled = true

                                Log.d(
                                    "JB_DSP",
                                    "Using Virtualizer"
                                )
                            }

                            Log.d(
                                "JB_DSP",
                                "SPATIAL AUDIO ENABLED"
                            )

                        } else {

                            virtualizer?.enabled = false
                            virtualizer?.release()
                            virtualizer = null

                            if (
                                Build.VERSION.SDK_INT >=
                                Build.VERSION_CODES.TIRAMISU
                            ) {
                                Log.d(
                                    "JB_DSP",
                                    "Spatializer handled by system"
                                )
                            }

                            Log.d(
                                "JB_DSP",
                                "SPATIAL AUDIO DISABLED"
                            )
                        }

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "DSP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ===== BASS BOOST =====
                "enableBassBoost" -> {

                    val enabled =
                        call.argument<Boolean>("enabled") ?: false

                    val strength =
                        call.argument<Int>("strength") ?: 700

                    val sessionId =
                        call.argument<Int>("sessionId") ?: 0

                    try {

                        if (enabled) {

                            bassBoost?.release()

                            bassBoost = BassBoost(
                                1000,
                                sessionId
                            )

                            if (bassBoost?.strengthSupported == true) {
                                bassBoost?.setStrength(
                                    strength.coerceIn(0, 1000).toShort()
                                )
                            }

                            bassBoost?.enabled = true

                            Log.d(
                                "JB_DSP",
                                "BASS BOOST ENABLED"
                            )

                        } else {

                            bassBoost?.enabled = false
                            bassBoost?.release()
                            bassBoost = null

                            Log.d(
                                "JB_DSP",
                                "BASS BOOST DISABLED"
                            )
                        }

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "DSP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ===== REVERB =====
                "enableReverb" -> {

                    val enabled =
                        call.argument<Boolean>("enabled") ?: false

                    val sessionId =
                        call.argument<Int>("sessionId") ?: 0

                    try {

                        if (enabled) {

                            reverb?.release()

                            reverb = EnvironmentalReverb(
                                1000,
                                sessionId
                            )

                            reverb?.roomLevel = (-1000).toShort()
                            reverb?.roomHFLevel = (-100).toShort()
                            reverb?.decayTime = 1500
                            reverb?.decayHFRatio = 500.toShort()
                            reverb?.reflectionsLevel = (-1000).toShort()
                            reverb?.reverbLevel = (-200).toShort()

                            reverb?.enabled = true

                            applyReverbPreset("hall")

                            Log.d(
                                "JB_DSP",
                                "REVERB ENABLED"
                            )

                        } else {

                            reverb?.enabled = false
                            reverb?.release()
                            reverb = null

                            Log.d(
                                "JB_DSP",
                                "REVERB DISABLED"
                            )
                        }

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "DSP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ===== REVERB PRESET =====
                "setReverbPreset" -> {

                    val preset =
                        call.argument<String>("preset")
                            ?: "hall"

                    try {

                        applyReverbPreset(
                            preset
                        )

                        Log.d(
                            "JB_DSP",
                            "REVERB PRESET = $preset"
                        )

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "DSP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ===== SPATIALIZER AVAILABILITY =====
                "isSpatializerAvailable" -> {

                    result.success(

                        Build.VERSION.SDK_INT >=
                                Build.VERSION_CODES.TIRAMISU &&
                                spatializer?.isAvailable == true
                    )
                }

                // ===== SPATIALIZER ENABLED =====
                "isSpatializerEnabled" -> {

                    result.success(
                        Build.VERSION.SDK_INT >=
                                Build.VERSION_CODES.TIRAMISU &&
                                spatializer?.isEnabled == true
                    )
                }

                // ===== EQUALIZER =====
                "enableEqualizer" -> {

                    val enabled =
                        call.argument<Boolean>("enabled") ?: false

                    val sessionId =
                        call.argument<Int>("sessionId") ?: 0

                    try {

                        if (enabled) {

                            equalizer?.release()

                            equalizer =
                                Equalizer(
                                    0,
                                    sessionId
                                )

                            equalizer?.enabled = true

                            Log.d(
                                "JB_DSP",
                                "Bands = ${equalizer?.numberOfBands}"
                            )

                            Log.d(
                                "JB_DSP",
                                "Presets = ${equalizer?.numberOfPresets}"
                            )

                            Log.d(
                                "JB_DSP",
                                "EQUALIZER ENABLED"
                            )

                        } else {

                            equalizer?.enabled = false
                            equalizer?.release()
                            equalizer = null

                            Log.d(
                                "JB_DSP",
                                "EQUALIZER DISABLED"
                            )
                        }

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "DSP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ===== SET BAND LEVEL =====
                "setBandLevel" -> {

                    val band =
                        call.argument<Int>("band") ?: 0

                    val level =
                        call.argument<Int>("level") ?: 0

                    try {

                        val range = equalizer?.bandLevelRange

                        val minLevel = range?.get(0)?.toInt() ?: -1500
                        val maxLevel = range?.get(1)?.toInt() ?: 1500

                        equalizer?.setBandLevel(
                            band.toShort(),
                            level.coerceIn(
                                minLevel,
                                maxLevel
                            ).toShort()
                        )

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "DSP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ===== BAND COUNT =====
                "getBandCount" -> {

                    result.success(
                        equalizer?.numberOfBands?.toInt() ?: 0
                    )
                }

                // ===== LEVEL RANGE =====
                "getBandLevelRange" -> {

                    val range =
                        equalizer?.bandLevelRange

                    result.success(
                        listOf(
                            range?.get(0)?.toInt() ?: -1500,
                            range?.get(1)?.toInt() ?: 1500
                        )
                    )
                }

                // ===== BAND FREQUENCY =====
                "getBandFrequency" -> {

                    val band =
                        call.argument<Int>("band") ?: 0

                    result.success(
                        equalizer?.getCenterFreq(
                            band.toShort()
                        )?.toInt()
                    )
                }

                // ===== PRESET COUNT =====
                "getPresetCount" -> {

                    result.success(
                        equalizer?.numberOfPresets?.toInt() ?: 0
                    )
                }

                // ===== APPLY PRESET =====
                "setPreset" -> {

                    val preset =
                        call.argument<Int>("preset") ?: 0

                    try {

                        val count =
                            equalizer?.numberOfPresets?.toInt() ?: 0

                        if (
                            preset >= 0 &&
                            preset < count
                        ) {

                            equalizer?.usePreset(
                                preset.toShort()
                            )
                        }

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "DSP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ===== PRESET NAME =====
                "getPresetName" -> {

                    val preset =
                        call.argument<Int>("preset") ?: 0

                    result.success(

                        equalizer?.getPresetName(
                            preset.toShort()
                        )
                    )
                }

                // ===== CURRENT PRESET =====
                "getCurrentPreset" -> {

                    result.success(
                        equalizer?.currentPreset?.toInt() ?: 0
                    )
                }

                // ===== LOUDNESS ENHANCER =====
                "enableLoudnessEnhancer" -> {

                    val enabled =
                        call.argument<Boolean>("enabled") ?: false

                    val sessionId =
                        call.argument<Int>("sessionId") ?: 0

                    try {

                        if (enabled) {

                            loudnessEnhancer?.release()

                            loudnessEnhancer =
                                LoudnessEnhancer(sessionId)

                            loudnessEnhancer?.enabled = true

                            Log.d(
                                "JB_DSP",
                                "LOUDNESS ENABLED"
                            )

                        } else {

                            loudnessEnhancer?.enabled = false
                            loudnessEnhancer?.release()
                            loudnessEnhancer = null

                            Log.d(
                                "JB_DSP",
                                "LOUDNESS DISABLED"
                            )
                        }

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "DSP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                // ===== SET GAIN =====
                "setLoudnessGain" -> {

                    val gain =
                        call.argument<Int>("gain") ?: 0

                    try {

                        loudnessEnhancer?.setTargetGain(
                            gain.coerceIn(
                                0,
                                10000
                            )
                        )

                        result.success(true)

                    } catch (e: Exception) {

                        result.error(
                            "DSP_ERROR",
                            e.message,
                            null
                        )
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {

        equalizer?.release()
        equalizer = null

        bassBoost?.release()
        bassBoost = null

        virtualizer?.release()
        virtualizer = null

        reverb?.release()
        reverb = null

        loudnessEnhancer?.release()
        loudnessEnhancer = null

        spatializer = null

        super.onDestroy()
    }
}