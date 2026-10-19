import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../analytics/analytics_service.dart';
import '../flavor/flavor_config.dart';

/// Servicio de notificaciones Push (FCM) + locales (BACKEND §6 / FRONTEND §8).
class PushNotificationsService {
  PushNotificationsService(this._messaging, this._localNotifications, this._analytics);

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final AnalyticsService _analytics;

  static const String _defaultChannelId = 'firebase_notifications_channel';
  static const String _campaignChannelId = 'firebase_campaigns_channel';
  static const String _remindersChannelId = 'reminders_channel';

  Future<void> init() async {
    // 1. Solicitar permisos (iOS y Android 13+)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Configurar canales en Android
    if (Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _defaultChannelId,
            'Notificaciones por defecto',
            description: 'Canal para alertas de la alcaldía',
            importance: Importance.high,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _campaignChannelId,
            'Notificaciones de Campañas',
            description: 'Canal para campañas informativas',
            importance: Importance.high,
          ),
        );
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            _remindersChannelId,
            'Recordatorios locales',
            description: 'Recordatorios de impuestos y eventos',
            importance: Importance.high,
          ),
        );
      }
    }

    // 3. Inicializar notificaciones locales para interacción al hacer click
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('ic_stat_reminder'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.startsWith('http')) {
          _launchUrl(payload);
        }
      },
    );

    // 4. Escuchar mensajes en primer plano (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
    });

    // 5. Escuchar apertura de notificaciones desde segundo plano/apagado (Background/Terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleMessageTap(message);
    });

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }
  }

  /// Último tópico suscrito con éxito en este proceso (`lastSubscribedTopic`
  /// del original): evita repetir la llamada cada vez que se reconstruye la Home.
  String? _lastSubscribedTopic;

  /// Suscripción al tópico del municipio: `theme_<NombreMunicipioNormalizado>`
  /// (puerto de `manageFirebaseSubscription` de `MunicipalityViewModel.kt`).
  ///
  /// Es **acumulativa** como en el original: al cambiar de municipio no se
  /// desuscribe del anterior.
  Future<void> subscribeToMunicipality(String name) async {
    final normalized = municipalitySlug(name);
    if (normalized.isEmpty) return;
    final topic = '${FlavorConfig.instance.fcmTopicPrefix}$normalized';
    if (topic == _lastSubscribedTopic) return;
    try {
      await _messaging.subscribeToTopic(topic);
      _lastSubscribedTopic = topic;
      await _analytics.logEvent('fcm_subscribed', parameters: {'topic': topic});
    } catch (_) {}
  }

  void _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final type = message.data['type'] ?? '';
    final url = message.data['url'] ?? '';
    final isCampaign = type == 'campaign' && url.isNotEmpty;

    final channelId = isCampaign ? _campaignChannelId : _defaultChannelId;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId == _campaignChannelId ? 'Campañas' : 'Notificaciones',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: url,
    );
  }

  void _handleMessageTap(RemoteMessage message) {
    final type = message.data['type'] ?? '';
    final url = message.data['url'] ?? '';
    if (type == 'campaign' && url.isNotEmpty) {
      _launchUrl(url);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

final pushNotificationsServiceProvider = Provider<PushNotificationsService>(
  (ref) => PushNotificationsService(
    FirebaseMessaging.instance,
    FlutterLocalNotificationsPlugin(),
    ref.watch(analyticsServiceProvider),
  ),
);
