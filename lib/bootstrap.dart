import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'app.dart';
import 'core/api/app_status.dart';
import 'core/flavor/flavor_config.dart';
import 'core/remote_config/remote_config_service.dart';
import 'core/storage/user_preferences.dart';

/// Inicialización común a todos los flavors. Cada `main_<flavor>.dart` delega
/// aquí. Todas las integraciones de Firebase van con guardas para que una config
/// incompleta (p. ej. iOS aún sin `GoogleService-Info.plist`) no tumbe el arranque.
Future<void> bootstrap(FlavorConfig config, FirebaseOptions options) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.instance = config;

  await Firebase.initializeApp(options: options);

  // Google Sign In v7.x mandatory initialization
  try {
    await GoogleSignIn.instance.initialize();
  } catch (_) {}

  // Crashlytics: captura errores de Flutter y de la zona raíz.
  try {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  } catch (_) {}

  // Messaging: permiso de notificaciones (no bloqueante).
  try {
    await FirebaseMessaging.instance.requestPermission();
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );

  // Remote Config: 4 keys + estado global de la app (BACKEND §6.1).
  try {
    final rc = RemoteConfigService(FirebaseRemoteConfig.instance);
    await rc.init();
    container
        .read(sendToWelcomeProvider.notifier)
        .set(rc.shouldSendToWelcome());
    final status = rc.toAppStatus();
    if (status.type != AppStatusType.operational) {
      container.read(appStatusProvider.notifier).updateStatus(status);
    }
  } catch (_) {}

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TramiApp(),
    ),
  );
}
