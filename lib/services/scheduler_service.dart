import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sinal_agendado.dart';
import '../services/audio_service_hybrid.dart';

// Serviço para agendar e executar sinais automaticamente
class SchedulerService {
  static final SchedulerService _instance = SchedulerService._internal();
  factory SchedulerService() => _instance;
  SchedulerService._internal();

  Timer? _timer;
  List<SinalAgendado> _sinaisAgendados = [];
  final List<SinalAgendado> _filaReproducao = [];
  final Set<String> _sinaisTocadosHoje = {};
  bool _executandoFila = false;
  final AudioServiceHybrid _audioService = AudioServiceHybrid();

  // Inicializar o scheduler
  void initialize() {
    // Parar timer anterior se existir
    _timer?.cancel();

    // Verificar a cada 1 minuto se há sinais para tocar
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _verificarSinaisParaTocar();
    });
    print('SchedulerService inicializado - verificando a cada minuto');

    // Fazer uma verificação inicial após 2 segundos
    Timer(const Duration(seconds: 2), () {
      _verificarSinaisParaTocar();
    });
  }

  // Atualizar lista de sinais agendados
  void atualizarSinais(List<SinalAgendado> sinais) {
    _sinaisAgendados = sinais.where((s) => s.ativo).toList();
    print('Sinais ativos atualizados: ${_sinaisAgendados.length}');
  }

  // Verificar se há sinais para tocar no momento atual
  void _verificarSinaisParaTocar() {
    try {
      final agora = DateTime.now();
      final sinaisParaTocar = <SinalAgendado>[];
      final chaveMinutoAtual =
          '${agora.year}-${agora.month}-${agora.day}-${agora.hour}-${agora.minute}';

      for (final sinal in _sinaisAgendados) {
        try {
          final chaveSinal = '${sinal.id}-$chaveMinutoAtual';
          final deveTocar = _deveTocarAgora(sinal, agora);
          final jaTocou = _sinaisTocadosHoje.contains(chaveSinal);

          if (deveTocar && !jaTocou) {
            sinaisParaTocar.add(sinal);
            _sinaisTocadosHoje.add(chaveSinal);
            print('Sinal para tocar: ${sinal.nome}');
          }
        } catch (e) {
          // Ignora erros individuais de sinais
          print('Erro ao processar sinal ${sinal.nome}: $e');
        }
      }

      // Limpar cache de sinais tocados do dia anterior
      _limparCacheAntigo(agora);

      if (sinaisParaTocar.isNotEmpty) {
        _adicionarNaFila(sinaisParaTocar);
      }
    } catch (e) {
      print('Erro na verificação: $e');
    }
  }

  // Verificar se um sinal deve tocar agora
  bool _deveTocarAgora(SinalAgendado sinal, DateTime agora) {
    try {
      final horarioSinal = TimeOfDay.fromDateTime(sinal.dataHora);
      final horarioAtual = TimeOfDay.fromDateTime(agora);

      // Verificar se o horário coincide exatamente (mesmo minuto)
      if (horarioSinal.hour != horarioAtual.hour ||
          horarioSinal.minute != horarioAtual.minute) {
        return false;
      }

      if (sinal.repetir && sinal.diasSemana.isNotEmpty) {
        // Verificar se hoje é um dos dias da semana selecionados
        final diaSemanaAtual = agora.weekday; // 1=segunda, 7=domingo
        return sinal.diasSemana.contains(diaSemanaAtual);
      } else {
        // Sinal único - verificar se é hoje
        final dataAlvo = DateTime(
          sinal.dataHora.year,
          sinal.dataHora.month,
          sinal.dataHora.day,
        );
        final dataHoje = DateTime(agora.year, agora.month, agora.day);
        return dataAlvo.isAtSameMomentAs(dataHoje);
      }
    } catch (e) {
      print('Erro ao verificar sinal ${sinal.nome}: $e');
      return false;
    }
  }

  // Adicionar sinais na fila de reprodução
  void _adicionarNaFila(List<SinalAgendado> sinais) {
    // Ordenar por prioridade/ordem de criação
    sinais.sort((a, b) => a.id.compareTo(b.id));

    for (final sinal in sinais) {
      if (!_filaReproducao.any((s) => s.id == sinal.id)) {
        _filaReproducao.add(sinal);
        print('Sinal adicionado à fila: ${sinal.nome}');
      }
    }

    if (!_executandoFila) {
      _executarFila();
    }
  }

  // Executar fila de reprodução
  Future<void> _executarFila() async {
    if (_executandoFila || _filaReproducao.isEmpty) return;

    _executandoFila = true;
    print('Iniciando execução da fila: ${_filaReproducao.length} sinais');

    while (_filaReproducao.isNotEmpty) {
      final sinal = _filaReproducao.removeAt(0);

      try {
        print('Tocando sinal da fila: ${sinal.nome} por ${sinal.duracao}s');
        await _audioService.tocarSinal(sinal);

        // Aguardar a duração do sinal antes de tocar o próximo
        await Future.delayed(Duration(seconds: sinal.duracao));

        // Parar o áudio atual antes do próximo
        await _audioService.pararMusica();

        // Pequena pausa entre os sinais
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Erro ao executar sinal da fila: $e');
        // Continuar com o próximo sinal mesmo se houver erro
      }
    }

    _executandoFila = false;
    print('Fila de reprodução concluída');
  }

  // Forçar verificação imediata (para testes)
  void verificarAgora() {
    print('Verificação forçada dos sinais...');
    _verificarSinaisParaTocar();
  }

  // Parar scheduler
  void dispose() {
    _timer?.cancel();
    _filaReproducao.clear();
    _executandoFila = false;
    print('SchedulerService finalizado');
  }

  // Limpar cache de sinais antigos
  void _limparCacheAntigo(DateTime agora) {
    final chaveHoje = '${agora.year}-${agora.month}-${agora.day}';
    _sinaisTocadosHoje.removeWhere((chave) => !chave.contains(chaveHoje));
  }

  // Getters para status
  int get tamanhoFila => _filaReproducao.length;
  bool get executandoFila => _executandoFila;
  List<String> get nomesNaFila => _filaReproducao.map((s) => s.nome).toList();
}
