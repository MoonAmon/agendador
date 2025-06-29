import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import '../models/sinal_agendado.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

// Função estática para tocar o alarme (necessária para o AlarmManager)
@pragma('vm:entry-point')
void alarmeCallback(int id) async {
  print('Alarme disparado com ID: $id');

  try {
    // Carregar sinais do storage
    final storageService = StorageService();
    final sinais = await storageService.carregarSinais();

    // Encontrar o sinal correspondente
    final sinal = sinais.firstWhere(
      (s) => s.id.hashCode == id,
      orElse: () => throw Exception('Sinal não encontrado'),
    );

    if (sinal.ativo) {
      // Tocar o áudio
      final audioService = AudioService();
      await audioService.tocarSinal(sinal);
      print('Áudio iniciado para sinal: ${sinal.nome}');
    }
  } catch (e) {
    print('Erro no callback do alarme: $e');
  }
}

// Serviço para gerenciar alarmes nativos do Android
class AlarmService {
  static final AlarmService _instance = AlarmService._internal();
  factory AlarmService() => _instance;
  AlarmService._internal();

  // Inicializar o serviço de alarmes
  Future<void> initialize() async {
    try {
      await AndroidAlarmManager.initialize();
    } catch (e) {
      print('Erro ao inicializar AlarmManager: $e');
    }
  }

  // Agendar um alarme para um sinal
  Future<void> agendarAlarme(SinalAgendado sinal) async {
    if (!sinal.ativo) return;

    try {
      final id = sinal.id.hashCode;

      if (sinal.repetir && sinal.diasSemana.isNotEmpty) {
        // Agendar para dias específicos da semana
        for (int dia in sinal.diasSemana) {
          final proximaData = _proximaDataParaDiaSemana(sinal.dataHora, dia);
          final alarmeId = int.parse('${id}$dia'.substring(0, 8));

          await AndroidAlarmManager.oneShotAt(
            proximaData,
            alarmeId,
            alarmeCallback,
            exact: true,
            wakeup: true,
          );

          print('Alarme agendado para ${proximaData} com ID: $alarmeId');
        }
      } else {
        // Agendar para data/hora específica
        await AndroidAlarmManager.oneShotAt(
          sinal.dataHora,
          id,
          alarmeCallback,
          exact: true,
          wakeup: true,
        );

        print('Alarme único agendado para ${sinal.dataHora} com ID: $id');
      }
    } catch (e) {
      print('Erro ao agendar alarme: $e');
    }
  }

  // Cancelar alarme de um sinal
  Future<void> cancelarAlarme(String sinalId) async {
    try {
      final id = sinalId.hashCode;
      await AndroidAlarmManager.cancel(id);
      print('Alarme cancelado com ID: $id');
    } catch (e) {
      print('Erro ao cancelar alarme: $e');
    }
  }

  // Cancelar todos os alarmes
  Future<void> cancelarTodosAlarmes() async {
    try {
      // Não há método para cancelar todos no android_alarm_manager_plus
      // Seria necessário manter uma lista de IDs ativos
      print('Cancelamento de todos os alarmes não implementado');
    } catch (e) {
      print('Erro ao cancelar todos os alarmes: $e');
    }
  }

  // Calcular próxima data para um dia da semana específico
  DateTime _proximaDataParaDiaSemana(DateTime base, int diaSemana) {
    final hoje = DateTime.now();
    final diasParaAdicionar = (diaSemana - hoje.weekday) % 7;

    var proximaData = DateTime(
      hoje.year,
      hoje.month,
      hoje.day + diasParaAdicionar,
      base.hour,
      base.minute,
      base.second,
    );

    // Se a data já passou hoje, adicionar uma semana
    if (proximaData.isBefore(hoje)) {
      proximaData = proximaData.add(const Duration(days: 7));
    }

    return proximaData;
  }
}
