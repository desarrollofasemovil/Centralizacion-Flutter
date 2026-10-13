import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Vuelta atrás defensiva para pantallas del `ShellRoute`.
///
/// Las rutas del `ShellRoute` del municipio son hermanas planas (paths
/// absolutos, no anidados), así que `context.go(X)` deja a `X` como ÚNICA
/// página de la pila. Ahí `Navigator.maybePop()` no hace nada y
/// `context.pop()` lanza `GoError: There is nothing to pop` (sale por
/// `FlutterError.onError`, no como crash visible): el botón Atrás se queda
/// muerto. Con esto siempre hay salida.
extension SafePop on BuildContext {
  /// Hace `pop()` si hay a dónde volver; si no, navega a [fallbackLocation].
  void popOrGo(String fallbackLocation) {
    if (canPop()) {
      pop();
    } else {
      go(fallbackLocation);
    }
  }
}

/// Home del municipio de la ruta actual (parámetro `:id`), o `null` si
/// [context] no está bajo una ruta de go_router con `:id` válido (p. ej. tests
/// de widget sin router).
String? municipalityHomeFallback(BuildContext context) {
  if (GoRouter.maybeOf(context) == null) return null;
  final GoRouterState state;
  try {
    state = GoRouterState.of(context);
  } on GoError {
    return null;
  }
  final id = int.tryParse(state.pathParameters['id'] ?? '');
  if (id == null || id == 0) return null;
  return AppRoutes.municipalityPath(id);
}
