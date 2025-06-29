import 'dart:async';
import 'package:flutter/material.dart';
import '../models/sinal_agendado.dart';
import '../services/audio_service.dart';

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
  final AudioService _audioService = AudioService();

  // Inicializar o scheduler
  void initialize() {
    // Verificar a cada 5 segundos se há sinais para tocar
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _verificarSinaisParaTocar();
    });
    print('SchedulerService inicializado - verificando a cada 5 segundos');

    // Fazer uma verificação inicial
    _verificarSinaisParaTocar();
  }

  // Atualizar lista de sinais agendados
  void atualizarSinais(List<SinalAgendado> sinais) {
    _sinaisAgendados = sinais.where((s) => s.ativo).toList();
    print('Sinais ativos atualizados: ${_sinaisAgendados.length}');
  }

  // Verificar se há sinais para tocar no momento atual
  void _verificarSinaisParaTocar() {
    final agora = DateTime.now();
    final sinaisParaTocar = <SinalAgendado>[];
    final chaveMinutoAtual =
        '${agora.year}-${agora.month}-${agora.day}-${agora.hour}-${agora.minute}';

    print(
      'Verificando sinais... Hora atual: ${agora.hour}:${agora.minute.toString().padLeft(2, '0')} - Sinais ativos: ${_sinaisAgendados.length}',
    );

    for (final sinal in _sinaisAgendados) {
      final chaveSinal = '${sinal.id}-$chaveMinutoAtual';
      final deveTocar = _deveTocarAgora(sinal, agora);
      final jaTocou = _sinaisTocadosHoje.contains(chaveSinal);

      print(
        'Sinal: ${sinal.nome} - Deve tocar: $deveTocar - Já tocou: $jaTocou',
      );

      if (deveTocar && !jaTocou) {
        sinaisParaTocar.add(sinal);
        _sinaisTocadosHoje.add(chaveSinal);
        print(
          '*** SINAL ADICIONADO PARA TOCAR: ${sinal.nome} às ${agora.hour}:${agora.minute} ***',
        );
      }
    }

    // Limpar cache de sinais tocados do dia anterior
    _limparCacheAntigo(agora);

    if (sinaisParaTocar.isNotEmpty) {
      print('Adicionando ${sinaisParaTocar.length} sinais na fila');
      _adicionarNaFila(sinaisParaTocar);
    }
  }

  // Verificar se um sinal deve tocar agora
  bool _deveTocarAgora(SinalAgendado sinal, DateTime agora) {
    final horarioSinal = TimeOfDay.fromDateTime(sinal.dataHora);
    final horarioAtual = TimeOfDay.fromDateTime(agora);

    print('  Verificando sinal: ${sinal.nome}');
    print(
      '  Horário do sinal: ${horarioSinal.hour}:${horarioSinal.minute.toString().padLeft(2, '0')}',
    );
    print(
      '  Horário atual: ${horarioAtual.hour}:${horarioAtual.minute.toString().padLeft(2, '0')}',
    );

    // Verificar se o horário coincide exatamente (mesmo minuto)
    if (horarioSinal.hour != horarioAtual.hour ||
        horarioSinal.minute != horarioAtual.minute) {
      print('  Horário não coincide');
      return false;
    }

    if (sinal.repetir && sinal.diasSemana.isNotEmpty) {
      // Verificar se hoje é um dos dias da semana selecionados
      final diaSemanaAtual = agora.weekday; // 1=segunda, 7=domingo
      final diasSelecionados = sinal.diasSemana;

      print(
        '  Dia da semana atual: $diaSemanaAtual (${_nomeDiaSemana(diaSemanaAtual)})',
      );
      print('  Dias selecionados: $diasSelecionados');

      final deveTocarHoje = diasSelecionados.contains(diaSemanaAtual);
      print('  Deve tocar hoje: $deveTocarHoje');

      return deveTocarHoje;
    } else {
      // Sinal único - verificar se é hoje
      final dataAlvo = DateTime(
        sinal.dataHora.year,
        sinal.dataHora.month,
        sinal.dataHora.day,
      );
      final dataHoje = DateTime(agora.year, agora.month, agora.day);
      final ehHoje = dataAlvo.isAtSameMomentAs(dataHoje);

      print(
        '  Data do sinal: ${dataAlvo.day}/${dataAlvo.month}/${dataAlvo.year}',
      );
      print('  Data hoje: ${dataHoje.day}/${dataHoje.month}/${dataHoje.year}');
      print('  É hoje: $ehHoje');

      return ehHoje;
    }
  }

  // Obter nome do dia da semana
  String _nomeDiaSemana(int dia) {
    const nomes = [
      '',
      'Segunda',
      'Terça',
      'Quarta',
      'Quinta',
      'Sexta',
      'Sábado',
      'Domingo',
    ];
    return nomes[dia];
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

  // Obter status da fila
  int get tamanhoFila => _filaReproducao.length;
  bool get executandoFila => _executandoFila;
  List<String> get nomesNaFila => _filaReproducao.map((s) => s.nome).toList();
}
