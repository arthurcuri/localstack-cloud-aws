import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._init();

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    // Inicializa os timezones
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // Configurações Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configurações iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Configurações Linux
    const linuxSettings = LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    // Configurações gerais
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicita permissões no Android 13+
    await _requestPermissions();
  }

  /// Solicita permissões de notificação
  Future<void> _requestPermissions() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }

    final iosImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (iosImplementation != null) {
      await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  /// Callback quando notificação é tocada
  void _onNotificationTapped(NotificationResponse response) {
    // Aqui você pode navegar para a tela da tarefa
    // Por enquanto apenas imprime no console
    print('Notificação tocada: ${response.payload}');
  }

  /// Agenda uma notificação para uma data/hora específica
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    // Garante que a data é no futuro
    if (scheduledDate.isBefore(DateTime.now())) {
      print('Data do lembrete já passou, não agendando notificação');
      return;
    }

    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Lembretes de Tarefas',
      channelDescription: 'Notificações de lembretes das suas tarefas',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const linuxDetails = LinuxNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      linux: linuxDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );

    print('Notificação agendada: $title para ${scheduledDate.toString()}');
  }

  /// Cancela uma notificação específica
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
    print('Notificação cancelada: $id');
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('Todas as notificações canceladas');
  }

  /// Mostra notificação imediata (para testes)
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'task_reminders',
      'Lembretes de Tarefas',
      channelDescription: 'Notificações de lembretes das suas tarefas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const linuxDetails = LinuxNotificationDetails();

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      linux: linuxDetails,
    );

    await _notifications.show(id, title, body, notificationDetails);
  }

  /// Gera ID único para notificação baseado no ID da tarefa
  static int getNotificationId(String taskId) {
    // Usa o hashCode da string como ID
    return taskId.hashCode.abs();
  }
}
