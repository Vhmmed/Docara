import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FcmService {
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    developer.log(
      'FCM permission: ${settings.authorizationStatus}',
      name: 'FcmService.init',
    );

    messaging.onTokenRefresh.listen(_onTokenRefreshed);
  }

  static Future<void> _onTokenRefreshed(String newToken) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': newToken})
          .eq('id', userId);
      developer.log('FCM token updated', name: 'FcmService._onTokenRefreshed');
    } catch (e) {
      developer.log(
        'Failed to update FCM token: $e',
        name: 'FcmService._onTokenRefreshed',
      );
    }
  }

  static Future<void> saveCurrentUserToken() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({'fcm_token': token})
          .eq('id', userId);
      developer.log('FCM token saved', name: 'FcmService.saveCurrentUserToken');
    } catch (e) {
      developer.log(
        'Failed to save FCM token: $e',
        name: 'FcmService.saveCurrentUserToken',
      );
    }
  }
}
