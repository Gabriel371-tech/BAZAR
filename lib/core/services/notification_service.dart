import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationTapped,
    );

    // Cria canais de notificação
    await _createNotificationChannels();
  }

  static Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel promotionChannel =
        AndroidNotificationChannel(
      'bazar_promotions',
      'Promoções',
      description: 'Notificações de promoções e ofertas especiais',
      importance: Importance.high,
    );

    const AndroidNotificationChannel updateChannel = AndroidNotificationChannel(
      'bazar_updates',
      'Atualizações',
      description: 'Notificações de atualizações de produtos',
      importance: Importance.high,
    );

    const AndroidNotificationChannel cartChannel = AndroidNotificationChannel(
      'bazar_cart',
      'Carrinho',
      description: 'Notificações relacionadas ao carrinho',
      importance: Importance.low,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(promotionChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(updateChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(cartChannel);
  }

  static void _handleNotificationTapped(NotificationResponse details) {
    // Trata cliques em notificações
  }

  /// Mostra uma notificação simples
  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channel = 'bazar_cart',
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channel,
      'Notificações Bazar',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  /// Mostra uma notificação de promoção
  static Future<void> showPromotionNotification({
    required int id,
    required String title,
    required String body,
    required String promotionCode,
  }) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        const AndroidNotificationDetails(
      'bazar_promotions',
      'Promoções',
      importance: Importance.high,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(''),
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      '$body - Cupom: $promotionCode',
      platformChannelSpecifics,
    );
  }

  /// Mostra uma notificação de atualização de produto
  static Future<void> showUpdateNotification({
    required int id,
    required String productName,
    required String updateMessage,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'bazar_updates',
      'Atualizações',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      'Atualização: $productName',
      updateMessage,
      platformChannelSpecifics,
    );
  }

  /// Agenda uma notificação de promoção para um tempo específico
  static Future<void> schedulePromotionNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String promotionCode,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'bazar_promotions',
        'Promoções',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        '$body - Cupom: $promotionCode',
        tz.TZDateTime.from(scheduledTime, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Erro ao agendar notificação: $e');
    }
  }

  /// Cancela uma notificação agendada
  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancela todas as notificações
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
