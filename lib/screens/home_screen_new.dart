import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/sinais_provider.dart';
import '../models/sinal_agendado.dart';
import 'adicionar_sinal_screen.dart';
import '../widgets/sinal_card.dart';
import '../test_audio.dart';
import '../services/audio_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Inicializar o provider quando a tela carrega
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SinaisProvider>(context, listen: false).initialize();
    });

    // Timer para atualizar a tela a cada 2 minutos
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      if (mounted) {
        setState(() {
          // Força rebuild para atualizar "próximo sinal"
        });
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agendador de Sinais'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Consumer<SinaisProvider>(
            builder: (context, provider, child) {
              if (provider.isPlaying) {
                return IconButton(
                  onPressed: () => provider.pararMusica(),
                  icon: const Icon(Icons.stop),
                  tooltip: 'Parar música atual',
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TestAudioScreen(),
                ),
              );
            },
            icon: const Icon(Icons.volume_up),
            tooltip: 'Testar Áudios',
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              final provider = Provider.of<SinaisProvider>(
                context,
                listen: false,
              );
              switch (value) {
                case 'refresh':
                  await provider.carregarSinais();
                  break;
                case 'check_now':
                  provider.verificarSinaisAgora();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verificando sinais agora...'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                  break;
                case 'debug_info':
                  _mostrarInfoDebug(context, provider);
                  break;
                case 'clear_all':
                  _mostrarDialogoConfirmacao(context, provider);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('Atualizar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'check_now',
                child: Row(
                  children: [
                    Icon(Icons.play_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text('Verificar Sinais Agora'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'debug_info',
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Info Debug'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_all',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Limpar Todos', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<SinaisProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar sinais',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.error!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.carregarSinais();
                    },
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            );
          }

          if (provider.sinais.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.alarm_off, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum sinal agendado',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toque no botão + para adicionar um novo sinal',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Status da fila de reprodução
              if (provider.filaReproducao > 0 || provider.executandoFila)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.queue_music, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Fila de Reprodução',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (provider.executandoFila)
                        const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 8),
                            Text('Executando...'),
                          ],
                        ),
                      if (provider.filaReproducao > 0)
                        Text('${provider.filaReproducao} sinais na fila'),
                      if (provider.nomesNaFila.isNotEmpty)
                        Text(
                          'Próximos: ${provider.nomesNaFila.take(3).join(', ')}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),

              // Status do próximo sinal
              if (provider.proximoSinal != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Próximo Sinal',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        provider.proximoSinal!.nome,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      Text(
                        _formatarProximaExecucao(provider.proximoSinal!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

              // Lista de sinais
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.sinais.length,
                  itemBuilder: (context, index) {
                    final sinal = provider.sinais[index];
                    return SinalCard(
                      sinal: sinal,
                      onEdit: () => _navegarParaEdicao(context, sinal),
                      onDelete: () =>
                          _confirmarExclusao(context, sinal, provider),
                      onToggle: () => provider.alternarAtivacao(sinal.id),
                      onPlay: () => provider.tocarSinal(sinal.id),
                      isPlaying: provider.currentSinalId == sinal.id,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navegarParaAdicao(context),
        tooltip: 'Adicionar Sinal',
        child: const Icon(Icons.add),
      ),
    );
  }

  void _navegarParaAdicao(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AdicionarSinalScreen()),
    );
  }

  void _navegarParaEdicao(BuildContext context, SinalAgendado sinal) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AdicionarSinalScreen(sinal: sinal),
      ),
    );
  }

  void _confirmarExclusao(
    BuildContext context,
    SinalAgendado sinal,
    SinaisProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Sinal'),
        content: Text('Deseja realmente excluir o sinal "${sinal.nome}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.removerSinal(sinal.id);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sinal "${sinal.nome}" excluído')),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoConfirmacao(
    BuildContext context,
    SinaisProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar Todos os Sinais'),
        content: const Text(
          'Deseja realmente excluir todos os sinais agendados? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              provider.limparTodos();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Todos os sinais foram excluídos'),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Limpar Todos'),
          ),
        ],
      ),
    );
  }

  void _mostrarInfoDebug(BuildContext context, SinaisProvider provider) {
    final agora = DateTime.now();
    final info = StringBuffer();

    info.writeln(
      '🕒 Hora atual: ${agora.hour.toString().padLeft(2, '0')}:${agora.minute.toString().padLeft(2, '0')}',
    );
    info.writeln('📊 Sinais ativos: ${provider.sinaisAtivos.length}');
    info.writeln('🎵 Fila: ${provider.filaReproducao} sinais');
    info.writeln('▶️ Executando: ${provider.executandoFila ? "Sim" : "Não"}');

    if (provider.proximoSinal != null) {
      final proximo = provider.proximoSinal!;
      final proximaExecucao = _formatarProximaExecucao(proximo);
      info.writeln('\n🔔 Próximo sinal:');
      info.writeln('   Nome: ${proximo.nome}');
      info.writeln('   Quando: $proximaExecucao');
      info.writeln('   Dias: ${proximo.diasSemana.join(', ')}');
      info.writeln('   Repetir: ${proximo.repetir ? "Sim" : "Não"}');
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Info'),
        content: SingleChildScrollView(child: Text(info.toString())),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  String _formatarProximaExecucao(SinalAgendado sinal) {
    final agora = DateTime.now();
    DateTime proximaExecucao;

    if (sinal.repetir && sinal.diasSemana.isNotEmpty) {
      // Para sinais repetitivos, calcular a próxima ocorrência
      proximaExecucao = _calcularProximaOcorrencia(sinal, agora);
    } else {
      // Para sinais únicos, usar a data/hora definida
      proximaExecucao = sinal.dataHora;
    }

    return _formatarDataHora(proximaExecucao);
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

  String _formatarDataHora(DateTime dataHora) {
    final agora = DateTime.now();
    final diferenca = dataHora.difference(agora);

    if (diferenca.inDays > 7) {
      return '${dataHora.day}/${dataHora.month}/${dataHora.year} às ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
    } else if (diferenca.inDays > 1) {
      final diasSemana = [
        '',
        'Segunda',
        'Terça',
        'Quarta',
        'Quinta',
        'Sexta',
        'Sábado',
        'Domingo',
      ];
      return '${diasSemana[dataHora.weekday]} às ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
    } else if (diferenca.inDays == 1) {
      return 'Amanhã às ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';
    } else if (diferenca.inHours > 0) {
      return 'Hoje às ${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')} (em ${diferenca.inHours}h ${diferenca.inMinutes % 60}min)';
    } else if (diferenca.inMinutes > 0) {
      return 'Em ${diferenca.inMinutes} minuto(s)';
    } else if (diferenca.inMinutes == 0) {
      return 'Agora!';
    } else {
      return 'Atrasado (${diferenca.inMinutes.abs()} min)';
    }
  }
}
