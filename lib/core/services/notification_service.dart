import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Trata mensagens em segundo plano
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

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

    // Inicializa FCM
    await _initFCM();
  }

  static Future<void> _initFCM() async {
    // Solicita permissão (especialmente para Android 13+)
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Usuário concedeu permissão de notificação');
    } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
      debugPrint('Usuário concedeu permissão provisória');
    } else {
      debugPrint('Usuário recusou ou não aceitou permissão de notificação');
    }

    // Obtém o token do dispositivo
    String? token = await _messaging.getToken();
    debugPrint("FCM Token: $token");

    // Configura o handler de segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listeners para mensagens em primeiro plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Mensagem recebida em primeiro plano: ${message.notification?.title}');
      
      if (message.notification != null) {
        showNotification(
          id: message.hashCode,
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
          channel: message.data['channel'] ?? 'bazar_updates',
        );
      }
    });

    // Quando o app é aberto via notificação (de background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App aberto via notificação: ${message.notification?.title}');
    });

    // Se o app foi aberto de um estado totalmente fechado (terminated)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App aberto de estado encerrado: ${initialMessage.notification?.title}');
    }
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
    String channel = 'bazar_updates',
  }) async {
    String channelName = 'Atualizações';
    if (channel == 'bazar_promotions') channelName = 'Promoções';
    if (channel == 'bazar_cart') channelName = 'Carrinho';

    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channel,
      channelName,
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
