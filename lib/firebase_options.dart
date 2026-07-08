import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        throw UnsupportedError(
          'Android is not yet configured. '
          'Run `flutterfire configure` to generate options.',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          '$defaultTargetPlatform is not supported.',
        );
    }
  }

  /// Populate these values from your GoogleService-Info.plist.
  ///
  /// | GoogleService-Info.plist key | Dart field          |
  /// |------------------------------|---------------------|
  /// | API_KEY                      | apiKey              |
  /// | GOOGLE_APP_ID                | appId               |
  /// | GCM_SENDER_ID                | messagingSenderId   |
  /// | PROJECT_ID                   | projectId           |
  /// | BUNDLE_ID (ios)              | iosBundleId         |
  /// | CLIENT_ID (ios)              | iosClientId         |
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBc7YY3a6Lj7fn6opKXAtWxb1eVZuUOaZg',
    appId: '1:471351358192:ios:2ad1130565773d55958835',
    messagingSenderId: '471351358192',
    projectId: 'docara-2ea55',
    iosBundleId: 'com.example.medicalBookingApp',
  );
}
