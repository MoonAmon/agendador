import 'package:audioplayers/audioplayers.dart';
import '../models/sinal_agendado.dart';

// Serviço para reprodução de áudio
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  String? _currentSinalId;

  bool get isPlaying => _isPlaying;
  String? get currentSinalId => _currentSinalId;

  // Inicializar ou recriar o player
  Future<void> _initializePlayer() async {
    try {
      // Limpar player anterior se existir
      await _disposePlayer();

      // Criar novo player
      _audioPlayer = AudioPlayer();
      print('AudioPlayer inicializado');
    } catch (e) {
      print('Erro ao inicializar AudioPlayer: $e');
    }
  }

  // Limpar player atual
  Future<void> _disposePlayer() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
        _audioPlayer!.dispose();
        _audioPlayer = null;
        _isPlaying = false;
        _currentSinalId = null;
        print('AudioPlayer limpo');
      }
    } catch (e) {
      print('Erro ao limpar AudioPlayer: $e');
    }
  }

  // Tocar música do sinal por duração especificada
  Future<void> tocarSinal(SinalAgendado sinal) async {
    // Redirecionar para o método mais robusto
    await tocarSinalSegundoPlano(sinal);
  }

  // Tocar sinal com configurações especiais para segundo plano
  Future<void> tocarSinalSegundoPlano(SinalAgendado sinal) async {
    try {
      print('Tentando tocar sinal em segundo plano: ${sinal.nome}');

      // Sempre inicializar um novo player para evitar problemas de estado
      await _initializePlayer();

      if (_audioPlayer == null) {
        print('Erro: AudioPlayer não pôde ser inicializado');
        return;
      }

      _currentSinalId = sinal.id;

      // Configurações especiais para segundo plano
      await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer!.setVolume(1.0);

      // Configurar contexto de áudio específico para alarmes
      await _audioPlayer!.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransient,
          ),
        ),
      );

      // Preparar fonte de áudio
      Source source;
      if (sinal.musicaPath.startsWith('/')) {
        source = DeviceFileSource(sinal.musicaPath);
      } else {
        source = AssetSource(sinal.musicaPath);
      }

      // Reproduzir com retry para segundo plano
      bool audioTocou = false;
      int tentativas = 0;
      const maxTentativas = 3;

      while (!audioTocou && tentativas < maxTentativas) {
        try {
          await _audioPlayer!.play(source);
          audioTocou = true;
          _isPlaying = true;
          print('Áudio tocando em segundo plano - tentativa ${tentativas + 1}');
        } catch (e) {
          tentativas++;
          print('Erro na tentativa $tentativas: $e');
          if (tentativas < maxTentativas) {
            // Recriar player a cada tentativa falhada
            await _initializePlayer();
            if (_audioPlayer == null) break;

            // Reconfigurar player
            await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
            await _audioPlayer!.setVolume(1.0);
            await _audioPlayer!.setAudioContext(
              AudioContext(
                android: AudioContextAndroid(
                  isSpeakerphoneOn: true,
                  stayAwake: true,
                  contentType: AndroidContentType.sonification,
                  usageType: AndroidUsageType.alarm,
                  audioFocus: AndroidAudioFocus.gainTransient,
                ),
              ),
            );

            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      if (!audioTocou) {
        print('Falhou ao tocar áudio após $maxTentativas tentativas');
        // Tentar com áudio padrão usando um novo player
        try {
          await _initializePlayer();
          if (_audioPlayer != null) {
            await _audioPlayer!.setReleaseMode(ReleaseMode.loop);
            await _audioPlayer!.setVolume(1.0);
            await _audioPlayer!.play(AssetSource('audio/default_alarm.mp3'));
            _isPlaying = true;
            print('Tocando áudio padrão como fallback');
          }
        } catch (e) {
          print('Erro ao tocar áudio padrão: $e');
        }
      }

      // Parar após duração especificada
      if (_isPlaying) {
        Future.delayed(Duration(seconds: sinal.duracao), () async {
          if (_currentSinalId == sinal.id) {
            await pararMusica();
            print('Áudio parado após ${sinal.duracao} segundos');
          }
        });
      }
    } catch (e) {
      print('Erro crítico ao tocar sinal em segundo plano: $e');
      _isPlaying = false;
      _currentSinalId = null;
    }
  }

  // Método para forçar reprodução mesmo em modo doze/standby
  Future<void> _forcarReproducao(Source source) async {
    try {
      if (_audioPlayer == null) return;

      // Tentar várias estratégias para garantir reprodução

      // Estratégia 1: Configurar player para alarme
      await _audioPlayer!.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
        ),
      );

      // Estratégia 2: Definir volume máximo
      await _audioPlayer!.setVolume(1.0);

      // Estratégia 3: Preparar o player primeiro
      await _audioPlayer!.setSource(source);
      await Future.delayed(const Duration(milliseconds: 100));

      // Estratégia 4: Play com retry
      await _audioPlayer!.resume();

      print('Reprodução forçada executada');
    } catch (e) {
      print('Erro ao forçar reprodução: $e');
    }
  }

  // Parar a música atual
  Future<void> pararMusica() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      }
      _isPlaying = false;
      _currentSinalId = null;
    } catch (e) {
      print('Erro ao parar música: $e');
      // Em caso de erro, limpar e recriar o player
      await _disposePlayer();
    }
  }

  // Pausar música
  Future<void> pausarMusica() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.pause();
      }
    } catch (e) {
      print('Erro ao pausar música: $e');
    }
  }

  // Retomar música
  Future<void> retomarMusica() async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.resume();
      }
    } catch (e) {
      print('Erro ao retomar música: $e');
    }
  }

  // Definir volume (0.0 a 1.0)
  Future<void> definirVolume(double volume) async {
    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.setVolume(volume.clamp(0.0, 1.0));
      }
    } catch (e) {
      print('Erro ao definir volume: $e');
    }
  }

  // Obter duração atual da reprodução
  Stream<Duration> get positionStream =>
      _audioPlayer?.onPositionChanged ?? const Stream.empty();

  // Limpar recursos
  void dispose() {
    _audioPlayer?.dispose();
  }
}
