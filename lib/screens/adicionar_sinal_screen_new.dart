import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/sinal_agendado.dart';
import '../providers/sinais_provider.dart';

class AdicionarSinalScreen extends StatefulWidget {
  final SinalAgendado? sinal;

  const AdicionarSinalScreen({super.key, this.sinal});

  @override
  State<AdicionarSinalScreen> createState() => _AdicionarSinalScreenState();
}

class _AdicionarSinalScreenState extends State<AdicionarSinalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _duracaoController = TextEditingController();
  DateTime _dataHoraSelecionada = DateTime.now().add(
    const Duration(minutes: 5),
  );
  int _duracao = 30; // segundos
  String _musicaSelecionada = 'audio/default_alarm.mp3';
  bool _repetir = false;
  List<int> _diasSemana = [];
  bool _ativo = true;
  bool _usarArquivoPersonalizado = false;
  String? _arquivoPersonalizadoPath;
  String? _arquivoPersonalizadoNome;

  final List<String> _musicasDisponiveis = [
    'audio/default_alarm.mp3',
    'audio/birds_singing.mp3',
    'audio/gentle_bell.mp3',
    'audio/nature_sounds.mp3',
    'audio/piano_melody.mp3',
  ];

  final List<String> _nomesMusicasAmigaveis = [
    'Alarme Padrão',
    'Canto dos Pássaros',
    'Sino Suave',
    'Sons da Natureza',
    'Melodia de Piano',
  ];

  final List<String> _nomesDiasSemana = [
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sábado',
    'Domingo',
  ];

  @override
  void initState() {
    super.initState();
    _duracaoController.text = _duracao.toString();

    if (widget.sinal != null) {
      _preencherCamposParaEdicao();
    }
  }

  void _preencherCamposParaEdicao() {
    final sinal = widget.sinal!;
    _nomeController.text = sinal.nome;
    _dataHoraSelecionada = sinal.dataHora;
    _duracao = sinal.duracao;
    _duracaoController.text = _duracao.toString();
    _repetir = sinal.repetir;
    _diasSemana = List.from(sinal.diasSemana);
    _ativo = sinal.ativo;

    // Verificar se é arquivo personalizado
    if (sinal.musicaPath.startsWith('/')) {
      _usarArquivoPersonalizado = true;
      _arquivoPersonalizadoPath = sinal.musicaPath;
      _arquivoPersonalizadoNome = sinal.musicaPath.split('/').last;
    } else {
      _musicaSelecionada = sinal.musicaPath;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sinal == null ? 'Novo Sinal' : 'Editar Sinal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: _salvarSinal,
            child: const Text(
              'SALVAR',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Nome do sinal
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome do Sinal',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, digite um nome para o sinal';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // Data e hora
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Data e Hora'),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(_dataHoraSelecionada),
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: _selecionarDataHora,
              ),
            ),

            const SizedBox(height: 16),

            // Duração em segundos
            TextFormField(
              controller: _duracaoController,
              decoration: const InputDecoration(
                labelText: 'Duração (segundos)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.timer),
                helperText: 'Tempo que o alarme tocará em segundos',
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor, digite a duração';
                }
                final duracao = int.tryParse(value);
                if (duracao == null || duracao <= 0) {
                  return 'Digite um número válido maior que 0';
                }
                if (duracao > 3600) {
                  return 'Duração máxima é 3600 segundos (1 hora)';
                }
                return null;
              },
              onChanged: (value) {
                final duracao = int.tryParse(value);
                if (duracao != null && duracao > 0) {
                  setState(() {
                    _duracao = duracao;
                  });
                }
              },
            ),

            const SizedBox(height: 16),

            // Seleção de música
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecionar Música',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Opção: Usar música pré-definida
                    RadioListTile<bool>(
                      title: const Text('Usar música pré-definida'),
                      value: false,
                      groupValue: _usarArquivoPersonalizado,
                      onChanged: (value) {
                        setState(() {
                          _usarArquivoPersonalizado = value!;
                          if (!_usarArquivoPersonalizado) {
                            _arquivoPersonalizadoPath = null;
                            _arquivoPersonalizadoNome = null;
                          }
                        });
                      },
                    ),

                    if (!_usarArquivoPersonalizado) ...[
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _musicaSelecionada,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.music_note),
                        ),
                        items: List.generate(_musicasDisponiveis.length, (
                          index,
                        ) {
                          return DropdownMenuItem(
                            value: _musicasDisponiveis[index],
                            child: Text(_nomesMusicasAmigaveis[index]),
                          );
                        }),
                        onChanged: (value) {
                          setState(() {
                            _musicaSelecionada = value!;
                          });
                        },
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Opção: Usar arquivo personalizado
                    RadioListTile<bool>(
                      title: const Text('Usar arquivo personalizado'),
                      value: true,
                      groupValue: _usarArquivoPersonalizado,
                      onChanged: (value) {
                        setState(() {
                          _usarArquivoPersonalizado = value!;
                        });
                      },
                    ),

                    if (_usarArquivoPersonalizado) ...[
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: _selecionarArquivoMusica,
                        icon: const Icon(Icons.folder_open),
                        label: Text(
                          _arquivoPersonalizadoNome ??
                              'Selecionar arquivo de áudio',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                      if (_arquivoPersonalizadoNome != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Arquivo selecionado: $_arquivoPersonalizadoNome',
                                  style: TextStyle(color: Colors.green[800]),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Repetir
            Card(
              child: SwitchListTile(
                title: const Text('Repetir'),
                subtitle: const Text('Repetir em dias específicos da semana'),
                value: _repetir,
                onChanged: (value) {
                  setState(() {
                    _repetir = value;
                    if (!_repetir) {
                      _diasSemana.clear();
                    }
                  });
                },
              ),
            ),

            // Seleção de dias da semana
            if (_repetir) ...[
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dias da Semana',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: List.generate(7, (index) {
                          final dia = index + 1;
                          final selecionado = _diasSemana.contains(dia);
                          return FilterChip(
                            label: Text(_nomesDiasSemana[index]),
                            selected: selecionado,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _diasSemana.add(dia);
                                } else {
                                  _diasSemana.remove(dia);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Ativo
            Card(
              child: SwitchListTile(
                title: const Text('Ativo'),
                subtitle: const Text('O sinal está ativo e será executado'),
                value: _ativo,
                onChanged: (value) {
                  setState(() {
                    _ativo = value;
                  });
                },
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _selecionarDataHora() async {
    final data = await showDatePicker(
      context: context,
      initialDate: _dataHoraSelecionada,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (data != null && mounted) {
      final hora = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dataHoraSelecionada),
      );

      if (hora != null) {
        setState(() {
          _dataHoraSelecionada = DateTime(
            data.year,
            data.month,
            data.day,
            hora.hour,
            hora.minute,
          );
        });
      }
    }
  }

  Future<void> _selecionarArquivoMusica() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _arquivoPersonalizadoPath = result.files.single.path!;
          _arquivoPersonalizadoNome = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao selecionar arquivo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _salvarSinal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validar arquivo personalizado
    if (_usarArquivoPersonalizado && _arquivoPersonalizadoPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, selecione um arquivo de áudio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar dias da semana se repetir estiver ativo
    if (_repetir && _diasSemana.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um dia da semana para repetição'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final musicaPath = _usarArquivoPersonalizado
          ? _arquivoPersonalizadoPath!
          : _musicaSelecionada;

      final sinal = SinalAgendado(
        id:
            widget.sinal?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        nome: _nomeController.text.trim(),
        dataHora: _dataHoraSelecionada,
        duracao: _duracao,
        musicaPath: musicaPath,
        ativo: _ativo,
        repetir: _repetir,
        diasSemana: _diasSemana,
      );

      final provider = Provider.of<SinaisProvider>(context, listen: false);

      if (widget.sinal == null) {
        await provider.adicionarSinal(sinal);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sinal criado com sucesso!')),
          );
        }
      } else {
        await provider.atualizarSinal(sinal);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sinal atualizado com sucesso!')),
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar sinal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _duracaoController.dispose();
    super.dispose();
  }
}
