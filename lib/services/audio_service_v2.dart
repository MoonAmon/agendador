import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../models/sinal_agendado.dart';

// Serviço de áudio otimizado para segundo plano
class AudioServiceV2 {
  static final AudioServiceV2 _instance = AudioServiceV2._internal();
  factory AudioServiceV2() => _instance;
  AudioServiceV2._internal();

  AudioPlayer? _primaryPlayer;
  AudioPlayer? _fallbackPlayer;
  bool _isPlaying = false;
  String? _currentSinalId;
  Timer? _stopTimer;
  StreamSubscription? _playerStateSubscription;

  bool get isPlaying => _isPlaying;
  String? get currentSinalId => _currentSinalId;

  // Tocar sinal em segundo plano com múltiplas estratégias
  Future<void> tocarSinalSegundoPlano(SinalAgendado sinal) async {
    print('=== INICIANDO REPRODUÇÃO EM SEGUNDO PLANO ===');
    print('Sinal: ${sinal.nome}');
    print('Arquivo: ${sinal.musicaPath}');
    print('Duração: ${sinal.duracao}s');

    try {
      // Parar qualquer reprodução anterior
      await _pararTodosPlayers();

      _currentSinalId = sinal.id;

      // Estratégia 1: Player principal
      bool tocouComSucesso = await _tentarTocarComPlayerPrincipal(sinal);

      if (!tocouComSucesso) {
        print('Player principal falhou, tentando fallback...');
        // Estratégia 2: Player de fallback
        tocouComSucesso = await _tentarTocarComPlayerFallback(sinal);
      }

      if (!tocouComSucesso) {
        print('Todos os players falharam, tentando áudio padrão...');
        // Estratégia 3: Áudio padrão
        await _tentarTocarAudioPadrao(sinal);
      }

      if (_isPlaying) {
        print('=== ÁUDIO REPRODUZINDO COM SUCESSO ===');
        // Usar Timer para maior precisão no controle de duração
        _stopTimer?.cancel();
        _stopTimer = Timer(Duration(seconds: sinal.duracao), () async {
          if (_currentSinalId == sinal.id) {
            await _pararTodosPlayers();
            print('=== ÁUDIO PARADO APÓS ${sinal.duracao}s ===');
          }
        });
      } else {
        print('=== FALHA EM TODAS AS ESTRATÉGIAS DE REPRODUÇÃO ===');
      }
    } catch (e) {
      print('=== ERRO CRÍTICO NA REPRODUÇÃO ===');
      print('Erro: $e');
      await _pararTodosPlayers();
    }
  }

  // Tentar tocar com player principal
  Future<bool> _tentarTocarComPlayerPrincipal(SinalAgendado sinal) async {
    try {
      print('Tentando player principal...');
      _primaryPlayer?.dispose();
      _primaryPlayer = AudioPlayer();

      await _configurarPlayerParaSegundoPlano(_primaryPlayer!);

      Source source = _obterSourceDoSinal(sinal);
      print('Source obtido: ${source.runtimeType}');

      // Para alarmes, usar modo loop para garantir que toque durante toda a duração
      await _primaryPlayer!.setReleaseMode(ReleaseMode.loop);

      await _primaryPlayer!.play(source);

      // Aguardar um pouco para verificar se realmente começou a tocar
      await Future.delayed(Duration(milliseconds: 500));

      if (_primaryPlayer!.state == PlayerState.playing) {
        _isPlaying = true;
        print('✓ Player principal: SUCESSO - Estado: ${_primaryPlayer!.state}');
        return true;
      } else {
        print('✗ Player principal: Estado inválido - ${_primaryPlayer!.state}');
        return false;
      }
    } catch (e) {
      print('✗ Player principal: FALHOU - $e');
      _primaryPlayer?.dispose();
      _primaryPlayer = null;
      return false;
    }
  }

  // Tentar tocar com player de fallback
  Future<bool> _tentarTocarComPlayerFallback(SinalAgendado sinal) async {
    try {
      print('Tentando player fallback...');
      _fallbackPlayer?.dispose();
      _fallbackPlayer = AudioPlayer();

      // Configuração mais robusta para fallback
      await _fallbackPlayer!.setReleaseMode(ReleaseMode.loop);
      await _fallbackPlayer!.setVolume(1.0);

      await _fallbackPlayer!.setAudioContext(
        AudioContext(
          android: AudioContextAndroid(
            isSpeakerphoneOn: true,
            stayAwake: true,
            contentType: AndroidContentType.music,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gain,
          ),
        ),
      );

      Source source = _obterSourceDoSinal(sinal);

      await _fallbackPlayer!.play(source);

      // Aguardar para verificar se começou a tocar
      await Future.delayed(Duration(milliseconds: 500));

      if (_fallbackPlayer!.state == PlayerState.playing) {
        _isPlaying = true;
        print('✓ Player fallback: SUCESSO - Estado: ${_fallbackPlayer!.state}');
        return true;
      } else {
        print('✗ Player fallback: Estado inválido - ${_fallbackPlayer!.state}');
        return false;
      }
    } catch (e) {
      print('✗ Player fallback: FALHOU - $e');
      _fallbackPlayer?.dispose();
      _fallbackPlayer = null;
      return false;
    }
  }

  // Tentar tocar áudio padrão
  Future<void> _tentarTocarAudioPadrao(SinalAgendado sinal) async {
    try {
      print('Tentando áudio padrão...');
      _primaryPlayer?.dispose();
      _primaryPlayer = AudioPlayer();

      await _configurarPlayerParaSegundoPlano(_primaryPlayer!);
      await _primaryPlayer!.setReleaseMode(ReleaseMode.loop);

      await _primaryPlayer!.play(AssetSource('audio/default_alarm.mp3'));

      // Aguardar para verificar se começou a tocar
      await Future.delayed(Duration(milliseconds: 500));

      if (_primaryPlayer!.state == PlayerState.playing) {
        _isPlaying = true;
        print('✓ Áudio padrão: SUCESSO - Estado: ${_primaryPlayer!.state}');
      } else {
        print('✗ Áudio padrão: Estado inválido - ${_primaryPlayer!.state}');
      }
    } catch (e) {
      print('✗ Áudio padrão: FALHOU - $e');
      _primaryPlayer?.dispose();
      _primaryPlayer = null;
    }
  }

  // Configurar player para reprodução em segundo plano
  Future<void> _configurarPlayerParaSegundoPlano(AudioPlayer player) async {
    try {
      // Configurar modo de release para não parar ao perder foco
      await player.setReleaseMode(ReleaseMode.stop);
      await player.setVolume(1.0);

      // Configuração específica para Android
      await player.setAudioContext(
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

      // Configurar listeners para monitorar estado
      _playerStateSubscription?.cancel();
      _playerStateSubscription = player.onPlayerStateChanged.listen((state) {
        print('Estado do player mudou: $state');
        if (state == PlayerState.completed || state == PlayerState.stopped) {
          _isPlaying = false;
        } else if (state == PlayerState.playing) {
          _isPlaying = true;
        }
      });
    } catch (e) {
      print('Erro ao configurar player: $e');
    }
  }

  // Obter source do sinal com validação
  Source _obterSourceDoSinal(SinalAgendado sinal) {
    print('Obtendo source para: ${sinal.musicaPath}');

    try {
      // Se o caminho começa com '/', é um arquivo do dispositivo
      if (sinal.musicaPath.startsWith('/')) {
        print('Usando DeviceFileSource');
        return DeviceFileSource(sinal.musicaPath);
      }
      // Se contém 'assets/', é um asset
      else if (sinal.musicaPath.contains('assets/')) {
        String assetPath = sinal.musicaPath.replaceFirst('assets/', '');
        print('Usando AssetSource: $assetPath');
        return AssetSource(assetPath);
      }
      // Caso contrário, tentar como asset
      else {
        print('Usando AssetSource (fallback): ${sinal.musicaPath}');
        return AssetSource(sinal.musicaPath);
      }
    } catch (e) {
      print('Erro ao obter source, usando padrão: $e');
      return AssetSource('audio/default_alarm.mp3');
    }
  }

  // Parar todos os players
  Future<void> _pararTodosPlayers() async {
    print('Parando todos os players...');

    // Cancelar timer se existir
    _stopTimer?.cancel();
    _stopTimer = null;

    // Cancelar subscription
    _playerStateSubscription?.cancel();
    _playerStateSubscription = null;

    try {
      if (_primaryPlayer != null) {
        await _primaryPlayer!.stop();
        _primaryPlayer!.dispose();
        _primaryPlayer = null;
        print('Player principal parado');
      }
    } catch (e) {
      print('Erro ao parar player principal: $e');
    }

    try {
      if (_fallbackPlayer != null) {
        await _fallbackPlayer!.stop();
        _fallbackPlayer!.dispose();
        _fallbackPlayer = null;
        print('Player fallback parado');
      }
    } catch (e) {
      print('Erro ao parar player fallback: $e');
    }

    _isPlaying = false;
    _currentSinalId = null;
    print('Todos os players foram parados');
  }

  // Métodos de compatibilidade
  Future<void> tocarSinal(SinalAgendado sinal) async {
    await tocarSinalSegundoPlano(sinal);
  }

  Future<void> pararMusica() async {
    await _pararTodosPlayers();
  }

  void dispose() {
    print('Dispose do AudioServiceV2');
    _stopTimer?.cancel();
    _playerStateSubscription?.cancel();
    _pararTodosPlayers();
  }

  // Método para forçar parada (útil para debugging)
  Future<void> forcarParada() async {
    print('=== FORÇANDO PARADA DE TODOS OS PLAYERS ===');
    await _pararTodosPlayers();
  }

  // Método para verificar status
  Map<String, dynamic> obterStatus() {
    return {
      'isPlaying': _isPlaying,
      'currentSinalId': _currentSinalId,
      'primaryPlayerState': _primaryPlayer?.state.toString(),
      'fallbackPlayerState': _fallbackPlayer?.state.toString(),
      'hasTimer': _stopTimer != null,
    };
  }
}
