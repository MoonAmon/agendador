import 'package:flutter/foundation.dart';
import '../models/sinal_agendado.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/audio_service.dart';
import '../services/alarm_service.dart';
import '../services/scheduler_service.dart';

// Provider para gerenciar o estado dos sinais agendados
class SinaisProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  final NotificationService _notificationService = NotificationService();
  final AudioService _audioService = AudioService();
  final AlarmService _alarmService = AlarmService();
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
    await _alarmService.initialize();
    await _notificationService.initialize();
    _notificationService.setNotificationCallback(tocarSinal);
    _schedulerService.initialize();
    await carregarSinais();
  }

  // Carregar sinais do armazenamento
  Future<void> carregarSinais() async {
    _setLoading(true);
    try {
      _sinais = await _storageService.carregarSinais();
      _schedulerService.atualizarSinais(_sinais);
      _error = null;
      notifyListeners();
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
      await _alarmService.agendarAlarme(sinal);

      if (!_sinais.any((s) => s.id == sinal.id)) {
        _sinais.add(sinal);
      }

      _schedulerService.atualizarSinais(_sinais);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao adicionar sinal: $e';
      print(_error);
    }
  }

  // Atualizar sinal existente
  Future<void> atualizarSinal(SinalAgendado sinal) async {
    try {
      await _storageService.salvarSinal(sinal, _sinais);

      // Cancelar notificação e alarme antigos e criar novos
      await _notificationService.cancelarSinal(sinal.id);
      await _alarmService.cancelarAlarme(sinal.id);

      if (sinal.ativo) {
        await _notificationService.agendarSinal(sinal);
        await _alarmService.agendarAlarme(sinal);
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
    }
  }

  // Remover sinal
  Future<void> removerSinal(String sinalId) async {
    try {
      await _storageService.removerSinal(sinalId, _sinais);
      await _notificationService.cancelarSinal(sinalId);
      await _alarmService.cancelarAlarme(sinalId);

      _sinais.removeWhere((sinal) => sinal.id == sinalId);

      _schedulerService.atualizarSinais(_sinais);
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao remover sinal: $e';
      print(_error);
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
    }
  }

  // Tocar sinal manualmente
  Future<void> tocarSinal(String sinalId) async {
    try {
      final sinal = _sinais.firstWhere((s) => s.id == sinalId);
      await _audioService.tocarSinal(sinal);
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao tocar sinal: $e';
      print(_error);
    }
  }

  // Parar música atual
  Future<void> pararMusica() async {
    try {
      await _audioService.pararMusica();
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao parar música: $e';
      print(_error);
    }
  }

  // Limpar todos os sinais
  Future<void> limparTodos() async {
    try {
      await _storageService.limparTodos();
      await _notificationService.cancelarTodos();
      _sinais.clear();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Erro ao limpar sinais: $e';
      print(_error);
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

    sinaisAtivos.sort((a, b) => a.dataHora.compareTo(b.dataHora));

    return sinaisAtivos.firstWhere(
      (sinal) => sinal.dataHora.isAfter(agora),
      orElse: () => sinaisAtivos.first,
    );
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
