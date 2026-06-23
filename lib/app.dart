import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/app_status.dart';
import 'core/flavor/flavor_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

/// Widget raíz. Navegación con go_router + tema neutro base (el tema del
/// municipio se aplica en el subárbol de `AlcaldiasScope`). Sobre todo se monta
/// un overlay de estado global que bloquea la UI ante `force_update` o
/// `server_error` bloqueante (FRONTEND §3).
class TramiApp extends ConsumerWidget {
  const TramiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final config = FlavorConfig.instance;
    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: buildInicialTheme(),
      darkTheme: buildInicialTheme(dark: true),
      routerConfig: router,
      builder: (context, child) =>
          _GlobalStatusOverlay(child: child ?? const SizedBox.shrink()),
    );
  }
}

class _GlobalStatusOverlay extends ConsumerWidget {
  const _GlobalStatusOverlay({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appStatusProvider);
    if (status.isBlocking) return _BlockingStatusScreen(status: status);
    return child;
  }
}

class _BlockingStatusScreen extends StatelessWidget {
  const _BlockingStatusScreen({required this.status});

  final AppStatus status;

  @override
  Widget build(BuildContext context) {
    final isForceUpdate = status.type == AppStatusType.forceUpdate;
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.red.shade700,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isForceUpdate ? Icons.system_update : Icons.cloud_off,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  status.title.isNotEmpty
                      ? status.title
                      : (isForceUpdate
                          ? 'Actualización requerida'
                          : 'Servicio no disponible'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (status.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    status.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
