import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/sinal_agendado.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../services/scheduler_service.dart';

// Provider para gerenciar o estado dos sinais agendados
class SinaisProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final AudioService _audioService = AudioService();
  final SchedulerService _schedulerService = SchedulerService();

  List<SinalAgendado> _sinais = [];
  bool _isLoading = false;
  String? _error;

  List<SinalAgendado> get sinais => _sinais;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPlaying => _audioService.isPlaying;
  String? get currentSinalId => _audioService.currentSinalId;

  // Status do scheduler
  int get filaReproducao => _schedulerService.tamanhoFila;
  bool get executandoFila => _schedulerService.executandoFila;
  List<String> get nomesNaFila => _schedulerService.nomesNaFila;

  // Inicializar o provider
  Future<void> initialize() async {
    try {
      await _notificationService.initialize();
      _notificationService.setNotificationCallback(tocarSinal);
      _schedulerService.initialize();
      await carregarSinais();
    } catch (e) {
      _error = 'Erro ao inicializar: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Carregar sinais do armazenamento
  Future<void> carregarSinais() async {
    _setLoading(true);
    try {
      _sinais = await _storageService.carregarSinais();
      _schedulerService.atualizarSinais(_sinais);
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar sinais: $e';
      print(_error);
    } finally {
      _setLoading(false);
    }
  }

  // Adicionar novo sinal
  Future<void> adicionarSinal(SinalAgendado sinal) async {
    try {
      await _storageService.salvarSinal(sinal, _sinais);
      await _notificationService.agendarSinal(sinal);

      if (!_sinais.any((s) => s.id == sinal.id)) {
        _sinais.add(sinal);
      }

      _schedulerService.atualizarSinais(_sinais);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao adicionar sinal: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Atualizar sinal existente
  Future<void> atualizarSinal(SinalAgendado sinal) async {
    try {
      await _storageService.salvarSinal(sinal, _sinais);
      // Cancelar notificação antiga e criar nova
      await _notificationService.cancelarSinal(sinal.id);

      if (sinal.ativo) {
        await _notificationService.agendarSinal(sinal);
      }

      final index = _sinais.indexWhere((s) => s.id == sinal.id);
      if (index >= 0) {
        _sinais[index] = sinal;
      }

      _schedulerService.atualizarSinais(_sinais);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao atualizar sinal: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Remover sinal
  Future<void> removerSinal(String sinalId) async {
    try {
      await _storageService.removerSinal(sinalId, _sinais);
      await _notificationService.cancelarSinal(sinalId);

      _sinais.removeWhere((sinal) => sinal.id == sinalId);

      _schedulerService.atualizarSinais(_sinais);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover sinal: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Ativar/Desativar sinal
  Future<void> alternarAtivacao(String sinalId) async {
    try {
      final index = _sinais.indexWhere((s) => s.id == sinalId);
      if (index >= 0) {
        final sinal = _sinais[index];
        final sinalAtualizado = sinal.copyWith(ativo: !sinal.ativo);

        await atualizarSinal(sinalAtualizado);
      }
    } catch (e) {
      _error = 'Erro ao alterar ativação do sinal: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Tocar sinal manualmente
  Future<void> tocarSinal(String sinalId) async {
    try {
      final sinal = _sinais.firstWhere((s) => s.id == sinalId);
      await _audioService.tocarSinal(sinal);
      // Notificar apenas quando necessário
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao tocar sinal: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Parar música atual
  Future<void> pararMusica() async {
    try {
      await _audioService.pararMusica();
      // Notificar apenas quando necessário
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao parar música: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Limpar todos os sinais
  Future<void> limparTodos() async {
    try {
      await _storageService.limparTodos();
      await _notificationService.cancelarTodos();
      _sinais.clear();
      _schedulerService.atualizarSinais(_sinais);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao limpar sinais: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Obter sinais ativos
  List<SinalAgendado> get sinaisAtivos =>
      _sinais.where((s) => s.ativo).toList();

  // Obter próximo sinal
  SinalAgendado? get proximoSinal {
    final agora = DateTime.now();
    final sinaisAtivos = this.sinaisAtivos;

    if (sinaisAtivos.isEmpty) return null;

    SinalAgendado? proximoSinal;
    DateTime? proximaExecucao;

    for (final sinal in sinaisAtivos) {
      DateTime? proximaDataSinal;

      if (sinal.repetir && sinal.diasSemana.isNotEmpty) {
        // Para sinais repetitivos, calcular a próxima ocorrência
        proximaDataSinal = _calcularProximaOcorrencia(sinal, agora);
      } else {
        // Para sinais únicos, usar a data/hora definida
        if (sinal.dataHora.isAfter(agora)) {
          proximaDataSinal = sinal.dataHora;
        }
      }

      if (proximaDataSinal != null) {
        if (proximaExecucao == null ||
            proximaDataSinal.isBefore(proximaExecucao)) {
          proximaExecucao = proximaDataSinal;
          proximoSinal = sinal;
        }
      }
    }

    return proximoSinal;
  }

  // Calcular próxima ocorrência de um sinal repetitivo
  DateTime _calcularProximaOcorrencia(SinalAgendado sinal, DateTime agora) {
    final horarioSinal = TimeOfDay.fromDateTime(sinal.dataHora);
    DateTime? proximaData;

    for (int diaSemana in sinal.diasSemana) {
      final diasParaAdicionar = (diaSemana - agora.weekday) % 7;

      var candidataData = DateTime(
        agora.year,
        agora.month,
        agora.day + diasParaAdicionar,
        horarioSinal.hour,
        horarioSinal.minute,
      );

      // Se a data é hoje mas o horário já passou, pular para a próxima semana
      if (candidataData.isBefore(agora) ||
          candidataData.isAtSameMomentAs(agora)) {
        candidataData = candidataData.add(const Duration(days: 7));
      }

      // Encontrar a próxima ocorrência mais cedo
      if (proximaData == null || candidataData.isBefore(proximaData)) {
        proximaData = candidataData;
      }
    }

    return proximaData ?? agora.add(const Duration(days: 1));
  }

  // Forçar verificação dos sinais (para testes)
  void verificarSinaisAgora() {
    _schedulerService.verificarAgora();
  }

  // Definir estado de carregamento
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Limpar erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _audioService.dispose();
    _schedulerService.dispose();
    super.dispose();
  }
}
