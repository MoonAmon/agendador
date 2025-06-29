import 'package:audioplayers/audioplayers.dart';
import '../models/sinal_agendado.dart';

// Serviço para reprodução de áudio
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentSinalId;

  bool get isPlaying => _isPlaying;
  String? get currentSinalId => _currentSinalId;

  // Tocar música do sinal por duração especificada
  Future<void> tocarSinal(SinalAgendado sinal) async {
    try {
      if (_isPlaying) {
        await pararMusica();
      }

      _currentSinalId = sinal.id;

      // Configurar o player
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(1.0);

      // Verificar se é arquivo local ou asset
      Source source;
      if (sinal.musicaPath.startsWith('/')) {
        // Arquivo local do dispositivo
        source = DeviceFileSource(sinal.musicaPath);
        print('Tentando tocar arquivo local: ${sinal.musicaPath}');
      } else {
        // Asset do app
        source = AssetSource(sinal.musicaPath);
        print('Tentando tocar asset: ${sinal.musicaPath}');
      }

      // Tentar reproduzir o áudio
      await _audioPlayer.play(source);
      _isPlaying = true;
      print('Áudio iniciado com sucesso para: ${sinal.nome}');

      // Parar após a duração especificada (em segundos)
      Future.delayed(Duration(seconds: sinal.duracao), () async {
        if (_currentSinalId == sinal.id) {
          await pararMusica();
          print('Áudio parado após ${sinal.duracao} segundos');
        }
      });
    } catch (e) {
      print('Erro ao tocar música: $e');
      _isPlaying = false;
      _currentSinalId = null;

      // Tentar com áudio padrão se falhar
      if (!sinal.musicaPath.contains('default_alarm.mp3')) {
        print('Tentando tocar áudio padrão...');
        final sinalPadrao = SinalAgendado(
          id: sinal.id,
          nome: sinal.nome,
          dataHora: sinal.dataHora,
          duracao: sinal.duracao,
          musicaPath: 'audio/default_alarm.mp3',
          ativo: sinal.ativo,
          repetir: sinal.repetir,
          diasSemana: sinal.diasSemana,
        );
        await tocarSinal(sinalPadrao);
      }
    }
  }

  // Parar a música atual
  Future<void> pararMusica() async {
    try {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentSinalId = null;
    } catch (e) {
      print('Erro ao parar música: $e');
    }
  }

  // Pausar música
  Future<void> pausarMusica() async {
    try {
      await _audioPlayer.pause();
    } catch (e) {
      print('Erro ao pausar música: $e');
    }
  }

  // Retomar música
  Future<void> retomarMusica() async {
    try {
      await _audioPlayer.resume();
    } catch (e) {
      print('Erro ao retomar música: $e');
    }
  }

  // Definir volume (0.0 a 1.0)
  Future<void> definirVolume(double volume) async {
    try {
      await _audioPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      print('Erro ao definir volume: $e');
    }
  }

  // Obter duração atual da reprodução
  Stream<Duration> get positionStream => _audioPlayer.onPositionChanged;

  // Limpar recursos
  void dispose() {
    _audioPlayer.dispose();
  }
}
