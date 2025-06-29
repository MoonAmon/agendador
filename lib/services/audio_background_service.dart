import 'package:flutter/services.dart';

/// Serviço para gerenciar áudio em segundo plano usando recursos nativos
class AudioBackgroundService {
  static const MethodChannel _channel = MethodChannel(
    'audio_background_service',
  );

  /// Inicializar o serviço nativo
  static Future<bool> initialize() async {
    try {
      final bool result = await _channel.invokeMethod('initialize');
      print('Serviço nativo inicializado: $result');
      return result;
    } catch (e) {
      print('Erro ao inicializar serviço nativo: $e');
      return false;
    }
  }

  /// Tocar áudio em segundo plano usando serviço nativo
  static Future<bool> playAudioInBackground({
    required String audioPath,
    required int durationSeconds,
    required String sinalId,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('playAudio', {
        'audioPath': audioPath,
        'duration': durationSeconds,
        'sinalId': sinalId,
      });
      print('Áudio iniciado via serviço nativo: $result');
      return result;
    } catch (e) {
      print('Erro ao tocar via serviço nativo: $e');
      return false;
    }
  }

  /// Parar áudio
  static Future<bool> stopAudio() async {
    try {
      final bool result = await _channel.invokeMethod('stopAudio');
      print('Áudio parado via serviço nativo: $result');
      return result;
    } catch (e) {
      print('Erro ao parar via serviço nativo: $e');
      return false;
    }
  }

  /// Verificar se há áudio tocando
  static Future<bool> isPlaying() async {
    try {
      final bool result = await _channel.invokeMethod('isPlaying');
      return result;
    } catch (e) {
      print('Erro ao verificar status via serviço nativo: $e');
      return false;
    }
  }

  /// Configurar volume
  static Future<bool> setVolume(double volume) async {
    try {
      final bool result = await _channel.invokeMethod('setVolume', {
        'volume': volume.clamp(0.0, 1.0),
      });
      return result;
    } catch (e) {
      print('Erro ao configurar volume via serviço nativo: $e');
      return false;
    }
  }
}
