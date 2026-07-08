import 'dart:developer' as developer;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medical_booking_app/core/services/chat_notification_listener.dart';
import 'package:medical_booking_app/core/services/fcm_service.dart';
import 'package:medical_booking_app/core/services/local_notification_service.dart';
import 'package:medical_booking_app/core/services/presence_service.dart';
import 'package:medical_booking_app/firebase_options.dart';
import 'package:medical_booking_app/core/di/injection_container.dart';
import 'package:medical_booking_app/splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load();

  initDependencies();

  developer.log('Initializing Firebase...', name: 'main');
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('Firebase initialized', name: 'main');
  } catch (e, s) {
    developer.log('Firebase init error: $e', name: 'main', error: e, stackTrace: s);
  }

  FcmService.init();

  developer.log('Initializing LocalNotificationService...', name: 'main');
  await LocalNotificationService.init();
  developer.log('LocalNotificationService.init() completed', name: 'main');

  developer.log('Initializing Supabase...', name: 'main');
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  developer.log('Supabase initialized', name: 'main');

  runApp(
    MedicalBookingApp(),
  );
}

class MedicalBookingApp extends StatefulWidget {
  MedicalBookingApp({super.key});

  @override
  State<MedicalBookingApp> createState() => _MedicalBookingAppState();
}

class _MedicalBookingAppState extends State<MedicalBookingApp>
    with WidgetsBindingObserver {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sl<PresenceService>().init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    developer.log(
      'didChangeAppLifecycleState: state=$state',
      name: 'main',
    );
    final presence = sl<PresenceService>();
    if (state == AppLifecycleState.resumed) {
      developer.log('LIFECYCLE: resumed — calling presence.init()', name: 'main');
      presence.init();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      developer.log(
        'LIFECYCLE: $state — calling presence.updateLastSeen() + presence.untrack()',
        name: 'main',
      );
      presence.updateLastSeen();
      presence.untrack();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sl<PresenceService>().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        splashColor: Colors.transparent,
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'IBM Plex Sans',
        textTheme: ThemeData.light().textTheme.apply(
          fontFamilyFallback: ['IBM Plex Sans Arabic'],
        ),
      ),
      home: ChatNotificationListener(
        navigatorKey: _navigatorKey,
        child: const SplashScreen(),
      ),
    );
  }
}
