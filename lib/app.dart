import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/app_status.dart';
import 'core/connectivity/connectivity_observer.dart';
import 'core/connectivity/connectivity_status.dart';
import 'core/connectivity/no_connection_notifier.dart';
import 'core/flavor/flavor_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/no_connection_dialog.dart';

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
          GlobalStatusOverlay(
        backButtonDispatcher: router.backButtonDispatcher,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

/// Capas globales sobre el árbol de navegación, por prioridad (FRONTEND §3):
/// estado bloqueante > diálogo sin conexión > contenido normal.
///
/// El diálogo se **superpone** (no reemplaza) al contenido: así no se destruye
/// el estado de go_router ni de los formularios. El `builder` de `MaterialApp`
/// queda por encima del `Navigator`, por eso no se usa `showDialog`.
class GlobalStatusOverlay extends ConsumerWidget {
  const GlobalStatusOverlay({
    required this.child,
    this.backButtonDispatcher,
    super.key,
  });

  final Widget child;

  /// Despachador de "atrás" del Router (`GoRouter.backButtonDispatcher`) en el
  /// que el diálogo registra su callback para tragarse el botón atrás.
  final BackButtonDispatcher? backButtonDispatcher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appStatusProvider);
    final dialogVisible = ref.watch(noConnectionDialogProvider);
    if (status.isBlocking) return _BlockingStatusScreen(status: status);

    final isConnectionRestored =
        ref.watch(connectivityStatusProvider).value ==
            ConnectivityStatus.available;
    return Stack(
      fit: StackFit.expand,
      children: [
        // Con el diálogo visible el contenido de abajo pierde el foco (cierra
        // el teclado y no recibe teclas). Siempre montado para no recrear el
        // subárbol al alternar.
        ExcludeFocus(excluding: dialogVisible, child: child),
        if (dialogVisible) ...[
          const ModalBarrier(dismissible: false, color: Colors.black54),
          Material(
            type: MaterialType.transparency,
            child: _BackBlocker(
              dispatcher: backButtonDispatcher,
              child: Center(
                child: NoConnectionDialog(
                  isConnectionRestored: isConnectionRestored,
                  onDismiss:
                      ref.read(noConnectionDialogProvider.notifier).dismiss,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Traga el "atrás" del sistema mientras está montado (Kotlin:
/// `onDismissRequest = {}`). El último callback registrado tiene prioridad
/// sobre el del Router, que se registró al arrancar.
class _BackBlocker extends StatefulWidget {
  const _BackBlocker({required this.dispatcher, required this.child});

  final BackButtonDispatcher? dispatcher;
  final Widget child;

  @override
  State<_BackBlocker> createState() => _BackBlockerState();
}

class _BackBlockerState extends State<_BackBlocker> {
  @override
  void initState() {
    super.initState();
    widget.dispatcher?.addCallback(_swallowBack);
  }

  @override
  void didUpdateWidget(_BackBlocker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dispatcher != widget.dispatcher) {
      oldWidget.dispatcher?.removeCallback(_swallowBack);
      widget.dispatcher?.addCallback(_swallowBack);
    }
  }

  @override
  void dispose() {
    widget.dispatcher?.removeCallback(_swallowBack);
    super.dispose();
  }

  Future<bool> _swallowBack() async => true;

  @override
  Widget build(BuildContext context) => widget.child;
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
