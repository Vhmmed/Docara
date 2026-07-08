import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Fires with the payload string whenever a local notification is tapped.
  /// The listener should consume the value and reset it to `null`.
  static final onNotificationTap = ValueNotifier<String?>(null);

  static Future<void> init() async {
    if (_initialized) {
      developer.log('Already initialized', name: 'LocalNotificationService');
      return;
    }
    _initialized = true;

    developer.log('Initializing...', name: 'LocalNotificationService');

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
      defaultPresentBanner: true,
      defaultPresentList: true,
    );

    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: androidSettings,
          iOS: iosSettings,
        ),
        onDidReceiveNotificationResponse: _onNotificationTap,
      );
      developer.log('Initialized successfully', name: 'LocalNotificationService');
    } catch (e) {
      developer.log('Initialize error: $e', name: 'LocalNotificationService', error: e);
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    onNotificationTap.value = response.payload;
  }

  static Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'chat_messages',
      'Chat Messages',
      channelDescription: 'New chat message notifications',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      presentBanner: true,
      presentList: true,
    );

    try {
      await _plugin.show(
        id,
        title,
        body,
        const NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: payload,
      );
    } catch (e) {
      developer.log(
        'showNotification error: $e',
        name: 'LocalNotificationService',
      );
    }
  }
}
