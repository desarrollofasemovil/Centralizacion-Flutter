import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/connectivity/connectivity_observer.dart';
import '../../../core/connectivity/connectivity_status.dart';
import '../../../core/connectivity/no_connection_notifier.dart';
import '../../../core/router/app_router.dart' show computeStartDestination;
import '../../../core/remote_config/remote_config_service.dart';
import '../../../core/storage/user_preferences.dart';

/// Pantalla de arranque (port de `ui/screen/splash/SplashScreen.kt`): fondo
/// `primarycolor` con el GIF de carga (`activity_splashscreen.xml`), visible
/// 3.6s antes de resolver la pantalla inicial real (welcome o municipio
/// guardado, ver FRONTEND §1.1). Antes de navegar comprueba la conectividad
/// (`checkConnectionAndProceed` del original): sin red muestra el diálogo sin
/// debounce y espera.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _splashElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Cuando el diálogo se cierra (volvió la red o "Entendido") se reevalúa.
    // Desviación del Kotlin: allí el Splash espera a que el usuario pulse
    // "Entendido"; aquí el diálogo global se cierra solo al volver la red.
    ref.listenManual<bool>(noConnectionDialogProvider, (previous, visible) {
      if (previous == true && !visible && _splashElapsed) _proceed();
    });
    Future.delayed(const Duration(milliseconds: 3600), () {
      _splashElapsed = true;
      _proceed();
    });
  }

  Future<void> _proceed() async {
    if (!mounted || _navigated) return;
    final status = await ref.read(connectivityObserverProvider).current();
    if (!mounted || _navigated) return;
    if (status == ConnectivityStatus.unavailable) {
      ref.read(noConnectionDialogProvider.notifier).show();
      return;
    }
    _navigated = true;
    final destination = computeStartDestination(
      sendToWelcome: ref.read(sendToWelcomeProvider),
      prefs: ref.read(userPreferencesProvider),
    );
    context.go(destination);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.primary,
      body: Center(
        child: Image.asset('assets/images/loadscreen.gif', width: 240),
      ),
    );
  }
}
