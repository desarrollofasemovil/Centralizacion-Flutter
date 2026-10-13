import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/api/app_status.dart';
import 'core/api/network_provider.dart';
import 'core/connectivity/connectivity_observer.dart';
import 'core/connectivity/connectivity_status.dart';
import 'core/connectivity/no_connection_notifier.dart';
import 'core/flavor/flavor_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_mode_provider.dart';
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
      builder: (context, child) {
        final app = GlobalStatusOverlay(
          backButtonDispatcher: router.backButtonDispatcher,
          child: child ?? const SizedBox.shrink(),
        );
        if (!NetworkProvider.isUsingDevServer) return app;
        // Marca inconfundible: con el override USE_DEV_SERVER los datos son
        // del servidor de pruebas, no de producción.
        return Banner(
          message: 'API DEV',
          location: BannerLocation.topEnd,
          textDirection: TextDirection.ltr,
          layoutDirection: TextDirection.ltr,
          child: app,
        );
      },
    );
  }
}

/// Capas globales sobre el árbol de navegación, por prioridad (FRONTEND §3):
/// estado bloqueante > diálogo sin conexión > contenido normal.
///
/// Ambas capas se **superponen** al contenido, nunca lo reemplazan: así no se
/// destruye el estado de go_router ni de los formularios. El `builder` de
/// `MaterialApp` queda por encima del `Navigator`, por eso no se usa
/// `showDialog`.
class GlobalStatusOverlay extends ConsumerWidget {
  const GlobalStatusOverlay({
    required this.child,
    this.backButtonDispatcher,
    super.key,
  });

  final Widget child;

  /// Despachador de "atrás" del Router (`GoRouter.backButtonDispatcher`) en el
  /// que las capas registran su callback para tragarse el botón atrás.
  final BackButtonDispatcher? backButtonDispatcher;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(appStatusProvider);
    final isBlocking = status.isBlocking;
    // El bloqueo tapa al diálogo: mientras esté activo el diálogo no se pinta
    // (aunque el notifier siga en `true`) y vuelve a salir al levantarse.
    final dialogVisible = ref.watch(noConnectionDialogProvider) && !isBlocking;

    final isConnectionRestored =
        ref.watch(connectivityStatusProvider).value ==
            ConnectivityStatus.available;

    // ⚠️ El estado bloqueante se pinta ENCIMA del router, nunca en su lugar.
    // Antes esto era `if (status.isBlocking) return _BlockingStatusScreen(...)`,
    // que sustituía el widget `Router`: un 5xx —de cualquier petición, incluso
    // de fondo— desmontaba el Navigator y con él el `State` de todas las
    // pantallas. Al levantarse el bloqueo el Router se remontaba desde cero:
    // formularios a medio llenar, pasos de asistente y scroll se perdían, y los
    // `Future` pendientes de pantallas desmontadas quedaban huérfanos.
    return Stack(
      // `expand` da constraints TIGHT al router; con `loose` el Navigator
      // podría resolverse a tamaño cero.
      fit: StackFit.expand,
      // No direccional: este `Stack` vive por encima de la `Directionality`
      // que aporta el árbol de `MaterialApp`.
      alignment: Alignment.topLeft,
      children: [
        // Con una capa visible el contenido de abajo pierde el foco (cierra el
        // teclado y no recibe teclas). Siempre en la misma posición del `Stack`
        // para no recrear el subárbol al alternar.
        ExcludeFocus(excluding: dialogVisible || isBlocking, child: child),
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
        // Capa superior. La barrera conserva la semántica del bloqueo anterior
        // (nada de abajo recibe toques; antes se lograba porque el router ni
        // existía) y `_BackBlocker` evita que el "atrás" del sistema haga pop
        // del router que sigue montado debajo.
        if (isBlocking) ...[
          const ModalBarrier(dismissible: false),
          _BackBlocker(
            dispatcher: backButtonDispatcher,
            child: _BlockingStatusScreen(
              status: status,
              // Este overlay vive por encima de `AlcaldiasScope`, así que no
              // hereda el modo oscuro del usuario: se lee aquí.
              dark: ref.watch(themeIsDarkProvider),
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

/// Pantalla de estado bloqueante (5xx, mantenimiento, force update). Fondo
/// claro u oscuro según el modo del usuario y textos en rojo de marca.
class _BlockingStatusScreen extends StatelessWidget {
  const _BlockingStatusScreen({required this.status, required this.dark});

  final AppStatus status;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isForceUpdate = status.type == AppStatusType.forceUpdate;
    final background =
        buildInicialTheme(dark: dark).colorScheme.surfaceContainerLowest;
    final red = brandErrorColor(dark: dark);
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: background,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isForceUpdate ? Icons.system_update : Icons.cloud_off,
                  color: red,
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
                  style: TextStyle(
                    color: red,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (status.message.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    status.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: red),
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
