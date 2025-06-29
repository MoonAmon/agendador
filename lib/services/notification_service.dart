import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/sinal_agendado.dart';

// Callback para quando a notificação for disparada
typedef OnNotificationCallback = Future<void> Function(String sinalId);

// Serviço para gerenciar notificações locais
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  OnNotificationCallback? _onNotificationCallback;

  // Configurar callback para quando notificação for disparada
  void setNotificationCallback(OnNotificationCallback callback) {
    _onNotificationCallback = callback;
  }

  // Inicializar o serviço de notificações
  Future<void> initialize() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicitar permissões
    await _requestPermissions();
  }

  // Solicitar permissões para notificações
  Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
      await androidPlugin.requestExactAlarmsPermission();
    }
  }

  // Callback quando notificação é tocada
  void _onNotificationTapped(NotificationResponse response) {
    // Executar callback se configurado
    if (_onNotificationCallback != null && response.payload != null) {
      _onNotificationCallback!(response.payload!);
    }
  }

  // Agendar uma notificação para um sinal
  Future<void> agendarSinal(SinalAgendado sinal) async {
    if (!sinal.ativo) return;

    const androidDetails = AndroidNotificationDetails(
      'sinal_channel',
      'Sinais Agendados',
      channelDescription: 'Notificações para sinais de música agendados',
      importance: Importance.max,
      priority: Priority.high,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      playSound: true,
      enableVibration: true,
      ongoing: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    if (sinal.repetir && sinal.diasSemana.isNotEmpty) {
      // Agendar para dias específicos da semana
      for (int dia in sinal.diasSemana) {
        final proximaData = _proximaDataParaDiaSemana(sinal.dataHora, dia);
        final id = int.parse('${sinal.id.hashCode}$dia'.substring(0, 8));

        await _notifications.zonedSchedule(
          id,
          'Sinal: ${sinal.nome}',
          'Música programada para tocar por ${_formatarDuracao(sinal.duracao)}',
          tz.TZDateTime.from(proximaData, tz.local),
          notificationDetails,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: sinal.id,
        );
      }
    } else {
      // Agendar para data/hora específica
      await _notifications.zonedSchedule(
        sinal.id.hashCode,
        'Sinal: ${sinal.nome}',
        'Música programada para tocar por ${_formatarDuracao(sinal.duracao)}',
        tz.TZDateTime.from(sinal.dataHora, tz.local),
        notificationDetails,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: sinal.id,
      );
    }
  }

  // Cancelar notificação de um sinal
  Future<void> cancelarSinal(String sinalId) async {
    await _notifications.cancel(sinalId.hashCode);
  }

  // Cancelar todas as notificações
  Future<void> cancelarTodos() async {
    await _notifications.cancelAll();
  }

  // Listar notificações pendentes
  Future<List<PendingNotificationRequest>> listarPendentes() async {
    return await _notifications.pendingNotificationRequests();
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
    );

    // Se a data já passou hoje, adicionar uma semana
    if (proximaData.isBefore(hoje)) {
      proximaData = proximaData.add(const Duration(days: 7));
    }

    return proximaData;
  }

  // Formatar duração em segundos para texto amigável
  String _formatarDuracao(int segundos) {
    if (segundos < 60) {
      return '$segundos segundos';
    } else if (segundos < 3600) {
      int minutos = segundos ~/ 60;
      int restoSegundos = segundos % 60;
      if (restoSegundos == 0) {
        return '$minutos ${minutos == 1 ? "minuto" : "minutos"}';
      } else {
        return '$minutos ${minutos == 1 ? "minuto" : "minutos"} e $restoSegundos ${restoSegundos == 1 ? "segundo" : "segundos"}';
      }
    } else {
      int horas = segundos ~/ 3600;
      int restoMinutos = (segundos % 3600) ~/ 60;
      return '$horas ${horas == 1 ? "hora" : "horas"}${restoMinutos > 0 ? " e $restoMinutos ${restoMinutos == 1 ? "minuto" : "minutos"}" : ""}';
    }
  }
}
