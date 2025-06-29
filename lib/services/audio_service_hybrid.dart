import 'dart:async';
import '../models/sinal_agendado.dart';
import 'audio_service_v2.dart';
import 'audio_background_service.dart';

/// Serviço híbrido que combina AudioServiceV2 com serviço nativo para máxima confiabilidade
class AudioServiceHybrid {
  static final AudioServiceHybrid _instance = AudioServiceHybrid._internal();
  factory AudioServiceHybrid() => _instance;
  AudioServiceHybrid._internal();

  final AudioServiceV2 _audioServiceV2 = AudioServiceV2();
  bool _nativeServiceAvailable = false;
  bool _isPlaying = false;
  String? _currentSinalId;
  Timer? _statusCheckTimer;

  bool get isPlaying => _isPlaying;
  String? get currentSinalId => _currentSinalId;

  /// Inicializar o serviço híbrido
  Future<void> initialize() async {
    print('=== INICIALIZANDO SERVIÇO HÍBRIDO ===');

    // Tentar inicializar serviço nativo
    try {
      _nativeServiceAvailable = await AudioBackgroundService.initialize();
      print('Serviço nativo disponível: $_nativeServiceAvailable');
    } catch (e) {
      print('Serviço nativo não disponível: $e');
      _nativeServiceAvailable = false;
    }
  }

  /// Tocar sinal usando estratégia híbrida
  Future<void> tocarSinal(SinalAgendado sinal) async {
    print('=== INICIANDO REPRODUÇÃO HÍBRIDA ===');
    print('Sinal: ${sinal.nome}');
    print('Arquivo: ${sinal.musicaPath}');
    print('Duração: ${sinal.duracao}s');
    print('Serviço nativo disponível: $_nativeServiceAvailable');

    await pararMusica(); // Parar qualquer reprodução anterior
    _currentSinalId = sinal.id;

    bool sucesso = false;

    // Estratégia 1: Tentar serviço nativo primeiro (mais confiável para segundo plano)
    if (_nativeServiceAvailable) {
      print('Tentando reprodução via serviço nativo...');
      sucesso = await _tentarReproducaoNativa(sinal);
    }

    // Estratégia 2: Fallback para AudioServiceV2
    if (!sucesso) {
      print('Serviço nativo falhou ou indisponível, usando AudioServiceV2...');
      try {
        await _audioServiceV2.tocarSinalSegundoPlano(sinal);
        sucesso = _audioServiceV2.isPlaying;
        print('AudioServiceV2 resultado: $sucesso');
      } catch (e) {
        print('AudioServiceV2 falhou: $e');
        sucesso = false;
      }
    }

    if (sucesso) {
      _isPlaying = true;
      print('=== REPRODUÇÃO HÍBRIDA INICIADA COM SUCESSO ===');
      _iniciarMonitoramento(sinal);
    } else {
      print('=== FALHA EM TODAS AS ESTRATÉGIAS HÍBRIDAS ===');
      _isPlaying = false;
      _currentSinalId = null;
    }
  }

  /// Tentar reprodução via serviço nativo
  Future<bool> _tentarReproducaoNativa(SinalAgendado sinal) async {
    try {
      String audioPath = sinal.musicaPath;

      // Converter path se necessário
      if (!audioPath.startsWith('/') && !audioPath.startsWith('assets/')) {
        audioPath = 'assets/$audioPath';
      }

      bool resultado = await AudioBackgroundService.playAudioInBackground(
        audioPath: audioPath,
        durationSeconds: sinal.duracao,
        sinalId: sinal.id,
      );

      if (resultado) {
        // Aguardar um pouco e verificar se realmente está tocando
        await Future.delayed(Duration(milliseconds: 1000));
        bool estaReproducindo = await AudioBackgroundService.isPlaying();
        print('Serviço nativo - está reproduzindo: $estaReproducindo');
        return estaReproducindo;
      }

      return false;
    } catch (e) {
      print('Erro na reprodução nativa: $e');
      return false;
    }
  }

  /// Iniciar monitoramento do status de reprodução
  void _iniciarMonitoramento(SinalAgendado sinal) {
    _statusCheckTimer?.cancel();

    // Verificar status a cada 2 segundos
    _statusCheckTimer = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _verificarStatus();
    });

    // Parar após a duração especificada
    Timer(Duration(seconds: sinal.duracao + 1), () async {
      if (_currentSinalId == sinal.id) {
        await pararMusica();
        print('=== REPRODUÇÃO HÍBRIDA FINALIZADA APÓS ${sinal.duracao}s ===');
      }
    });
  }

  /// Verificar status atual de reprodução
  Future<void> _verificarStatus() async {
    if (!_isPlaying) return;

    bool nativeIsPlaying = false;
    bool v2IsPlaying = false;

    if (_nativeServiceAvailable) {
      try {
        nativeIsPlaying = await AudioBackgroundService.isPlaying();
      } catch (e) {
        print('Erro ao verificar status nativo: $e');
      }
    }

    v2IsPlaying = _audioServiceV2.isPlaying;

    bool currentlyPlaying = nativeIsPlaying || v2IsPlaying;

    if (_isPlaying && !currentlyPlaying) {
      print('Reprodução parou inesperadamente, tentando restaurar...');
      // Aqui poderia implementar lógica de recuperação
    }

    _isPlaying = currentlyPlaying;

    print(
      'Status check - Nativo: $nativeIsPlaying, V2: $v2IsPlaying, Total: $_isPlaying',
    );
  }

  /// Parar reprodução
  Future<void> pararMusica() async {
    print('=== PARANDO REPRODUÇÃO HÍBRIDA ===');

    _statusCheckTimer?.cancel();
    _statusCheckTimer = null;

    // Parar serviço nativo
    if (_nativeServiceAvailable) {
      try {
        await AudioBackgroundService.stopAudio();
        print('Serviço nativo parado');
      } catch (e) {
        print('Erro ao parar serviço nativo: $e');
      }
    }

    // Parar AudioServiceV2
    try {
      await _audioServiceV2.pararMusica();
      print('AudioServiceV2 parado');
    } catch (e) {
      print('Erro ao parar AudioServiceV2: $e');
    }

    _isPlaying = false;
    _currentSinalId = null;
    print('=== REPRODUÇÃO HÍBRIDA PARADA ===');
  }

  /// Configurar volume
  Future<void> configurarVolume(double volume) async {
    if (_nativeServiceAvailable) {
      try {
        await AudioBackgroundService.setVolume(volume);
      } catch (e) {
        print('Erro ao configurar volume nativo: $e');
      }
    }
  }

  /// Obter status detalhado
  Map<String, dynamic> obterStatus() {
    Map<String, dynamic> status = {
      'isPlaying': _isPlaying,
      'currentSinalId': _currentSinalId,
      'nativeServiceAvailable': _nativeServiceAvailable,
      'hasStatusTimer': _statusCheckTimer != null,
    };

    // Adicionar status do AudioServiceV2
    status.addAll(_audioServiceV2.obterStatus());

    return status;
  }

  /// Dispose
  void dispose() {
    print('Dispose do AudioServiceHybrid');
    _statusCheckTimer?.cancel();
    pararMusica();
    _audioServiceV2.dispose();
  }
}
