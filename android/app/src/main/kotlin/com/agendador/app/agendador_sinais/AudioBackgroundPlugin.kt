package com.agendador.app.agendador_sinais

import android.content.Context
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.PowerManager
import android.util.Log
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.IOException
import java.util.*

class AudioBackgroundPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private var mediaPlayer: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var currentSinalId: String? = null
    private var stopTimer: Timer? = null

    companion object {
        private const val CHANNEL = "audio_background_service"
        private const val TAG = "AudioBackgroundPlugin"
    }

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler(this)
        context = flutterPluginBinding.applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> {
                try {
                    initialize()
                    result.success(true)
                } catch (e: Exception) {
                    Log.e(TAG, "Erro ao inicializar: ${e.message}")
                    result.success(false)
                }
            }
            "playAudio" -> {
                val audioPath = call.argument<String>("audioPath")
                val duration = call.argument<Int>("duration")
                val sinalId = call.argument<String>("sinalId")
                
                if (audioPath != null && duration != null && sinalId != null) {
                    playAudio(audioPath, duration, sinalId, result)
                } else {
                    result.success(false)
                }
            }
            "stopAudio" -> {
                stopAudio()
                result.success(true)
            }
            "isPlaying" -> {
                result.success(isPlaying())
            }
            "setVolume" -> {
                val volume = call.argument<Double>("volume")
                if (volume != null) {
                    setVolume(volume.toFloat())
                    result.success(true)
                } else {
                    result.success(false)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initialize() {
        Log.d(TAG, "Inicializando AudioBackgroundPlugin")
        
        // Obter WakeLock para manter o dispositivo ativo
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "AudioBackgroundPlugin::WakeLock"
        )
    }

    private fun playAudio(audioPath: String, duration: Int, sinalId: String, result: Result) {
        Log.d(TAG, "Tentando reproduzir: $audioPath por ${duration}s")
        
        try {
            // Parar reprodução anterior
            stopAudio()
            
            currentSinalId = sinalId
            
            // Criar MediaPlayer
            mediaPlayer = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .build()
                )
                
                // Configurar source
                if (audioPath.startsWith("assets/")) {
                    val assetPath = audioPath.removePrefix("assets/")
                    val afd = context.assets.openFd(assetPath)
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                } else {
                    setDataSource(audioPath)
                }
                
                // Configurar loop
                isLooping = true
                
                // Configurar listeners
                setOnPreparedListener { mp ->
                    Log.d(TAG, "MediaPlayer preparado, iniciando reprodução")
                    mp.start()
                    
                    // Adquirir WakeLock
                    wakeLock?.takeIf { !it.isHeld }?.acquire(duration * 1000L + 5000L)
                    
                    // Configurar timer para parar
                    stopTimer = Timer()
                    stopTimer?.schedule(object : TimerTask() {
                        override fun run() {
                            if (currentSinalId == sinalId) {
                                Log.d(TAG, "Timer expirou, parando reprodução")
                                stopAudio()
                            }
                        }
                    }, duration * 1000L)
                    
                    result.success(true)
                }
                
                setOnErrorListener { _, what, extra ->
                    Log.e(TAG, "Erro no MediaPlayer: what=$what, extra=$extra")
                    result.success(false)
                    true
                }
                
                setOnCompletionListener {
                    Log.d(TAG, "Reprodução completada")
                    stopAudio()
                }
                
                prepareAsync()
            }
            
        } catch (e: IOException) {
            Log.e(TAG, "Erro ao reproduzir áudio: ${e.message}")
            result.success(false)
        } catch (e: Exception) {
            Log.e(TAG, "Erro inesperado: ${e.message}")
            result.success(false)
        }
    }

    private fun stopAudio() {
        Log.d(TAG, "Parando reprodução")
        
        stopTimer?.cancel()
        stopTimer = null
        
        try {
            mediaPlayer?.let { mp ->
                if (mp.isPlaying) {
                    mp.stop()
                }
                mp.release()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao parar MediaPlayer: ${e.message}")
        }
        
        mediaPlayer = null
        currentSinalId = null
        
        // Liberar WakeLock
        wakeLock?.takeIf { it.isHeld }?.release()
    }

    private fun isPlaying(): Boolean {
        return try {
            mediaPlayer?.isPlaying == true
        } catch (e: Exception) {
            false
        }
    }

    private fun setVolume(volume: Float) {
        try {
            val clampedVolume = volume.coerceIn(0f, 1f)
            mediaPlayer?.setVolume(clampedVolume, clampedVolume)
            Log.d(TAG, "Volume configurado para: $clampedVolume")
        } catch (e: Exception) {
            Log.e(TAG, "Erro ao configurar volume: ${e.message}")
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        stopAudio()
    }
}
