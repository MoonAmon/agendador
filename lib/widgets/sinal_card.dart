import 'package:flutter/material.dart';
import '../models/sinal_agendado.dart';

class SinalCard extends StatelessWidget {
  final SinalAgendado sinal;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggle;
  final VoidCallback? onPlay;
  final bool isPlaying;

  const SinalCard({
    super.key,
    required this.sinal,
    this.onEdit,
    this.onDelete,
    this.onToggle,
    this.onPlay,
    this.isPlaying = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: sinal.ativo ? 2 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isPlaying ? Border.all(color: Colors.green, width: 2) : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                sinal.ativo ? Icons.alarm : Icons.alarm_off,
                color: sinal.ativo ? Colors.green : Colors.grey,
                size: 28,
              ),
              if (isPlaying)
                const Icon(Icons.music_note, color: Colors.green, size: 16),
            ],
          ),
          title: Text(
            sinal.nome,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: sinal.ativo ? Colors.black : Colors.grey,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatarDataHora(sinal.dataHora),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    _formatarDuracao(sinal.duracao),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (sinal.repetir) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.repeat, size: 16, color: Colors.blue[600]),
                    const SizedBox(width: 4),
                    Text(
                      _formatarDiasRepetir(sinal.diasSemana),
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ],
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onPlay != null)
                IconButton(
                  onPressed: isPlaying ? null : onPlay,
                  icon: Icon(
                    isPlaying ? Icons.music_note : Icons.play_arrow,
                    color: isPlaying ? Colors.green : Colors.blue,
                  ),
                  tooltip: isPlaying ? 'Tocando...' : 'Tocar agora',
                ),
              if (onToggle != null)
                Switch(
                  value: sinal.ativo,
                  onChanged: (value) => onToggle?.call(),
                  activeColor: Colors.green,
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 20),
                        SizedBox(width: 8),
                        Text('Editar'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Excluir', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatarDataHora(DateTime dataHora) {
    final agora = DateTime.now();
    final hoje = DateTime(agora.year, agora.month, agora.day);
    final dataEscolhida = DateTime(dataHora.year, dataHora.month, dataHora.day);

    String horario =
        '${dataHora.hour.toString().padLeft(2, '0')}:${dataHora.minute.toString().padLeft(2, '0')}';

    if (dataEscolhida == hoje) {
      return 'Hoje às $horario';
    } else if (dataEscolhida == hoje.add(const Duration(days: 1))) {
      return 'Amanhã às $horario';
    } else {
      return '${dataHora.day.toString().padLeft(2, '0')}/${dataHora.month.toString().padLeft(2, '0')} às $horario';
    }
  }

  String _formatarDiasRepetir(List<int> dias) {
    if (dias.isEmpty) return '';

    const nomesDias = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    if (dias.length == 7) {
      return 'Todos os dias';
    } else if (dias.length == 5 && !dias.contains(6) && !dias.contains(7)) {
      return 'Dias úteis';
    } else if (dias.length == 2 && dias.contains(6) && dias.contains(7)) {
      return 'Fins de semana';
    } else {
      return dias.map((dia) => nomesDias[dia - 1]).join(', ');
    }
  }

  String _formatarDuracao(int segundos) {
    if (segundos < 60) {
      return '$segundos seg';
    } else if (segundos < 3600) {
      int minutos = segundos ~/ 60;
      int restoSegundos = segundos % 60;
      if (restoSegundos == 0) {
        return '$minutos min';
      } else {
        return '${minutos}min ${restoSegundos}seg';
      }
    } else {
      int horas = segundos ~/ 3600;
      int restoMinutos = (segundos % 3600) ~/ 60;
      int restoSegundos = segundos % 60;
      String resultado = '${horas}h';
      if (restoMinutos > 0) resultado += ' ${restoMinutos}min';
      if (restoSegundos > 0) resultado += ' ${restoSegundos}seg';
      return resultado;
    }
  }
}
