import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart' show computeStartDestination;
import '../../../core/remote_config/remote_config_service.dart';
import '../../../core/storage/user_preferences.dart';

/// Pantalla de arranque (port de `ui/screen/splash/SplashScreen.kt`): fondo
/// `primarycolor` con el GIF de carga (`activity_splashscreen.xml`), visible
/// 3.6s antes de resolver la pantalla inicial real (welcome o municipio
/// guardado, ver FRONTEND §1.1).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3600), _proceed);
  }

  void _proceed() {
    if (!mounted) return;
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
