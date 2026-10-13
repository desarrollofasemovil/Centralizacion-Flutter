import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

/// Port de `ui/navigation/NavigationAnimations.kt` y del `NavHost` de
/// `AppNavGraph.kt`.
///
/// En Compose cada destino declara cuatro transiciones; en Flutter cada
/// `Page` recibe `animation` (su propia entrada / salida con back) y
/// `secondaryAnimation` (cuando otra pantalla lo cubre / lo descubre):
///
/// | Compose            | Flutter                                |
/// |--------------------|----------------------------------------|
/// | enterTransition    | `animation` hacia adelante             |
/// | popExitTransition  | `animation` en reversa                 |
/// | exitTransition     | `secondaryAnimation` hacia adelante    |
/// | popEnterTransition | `secondaryAnimation` en reversa        |
enum NavTransition {
  /// Defecto del `NavHost` (`AppNavGraph.kt`): desliza el ancho completo,
  /// 300 ms, sin fade.
  standard(Duration(milliseconds: 300)),

  /// `slideInFromRight` / `slideOutToLeft` / ... de `NavigationAnimations.kt`:
  /// 500 ms, fade, y la pantalla de atrás sólo se desplaza un tercio.
  parallax(Duration(milliseconds: 500));

  const NavTransition(this.duration);
  final Duration duration;
}

/// Construye la página de una ruta con las transiciones de Compose.
///
/// [enter] gobierna entrada y salida con back de esta pantalla; [exit]
/// gobierna cómo se va cuando otra pantalla se apila encima y cómo vuelve.
/// Ambos valen [NavTransition.standard] salvo que el `composable(...)` Kotlin
/// de la pantalla los sobreescriba.
///
/// En iOS se conserva la página nativa para no perder el gesto de "deslizar
/// para volver" (Android no lo tiene, así que no hay nada que portar).
Page<void> appPage(
  GoRouterState state,
  Widget child, {
  NavTransition enter = NavTransition.standard,
  NavTransition exit = NavTransition.standard,
}) {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return CupertinoPage<void>(key: state.pageKey, child: child);
  }
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: enter.duration,
    reverseTransitionDuration: enter.duration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // FastOutSlowInEasing en ambos sentidos: al ir en reversa se usa la
      // curva invertida para que el back también "frene" al final.
      final enterProgress = CurvedAnimation(
        parent: animation,
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped,
      );
      final exitProgress = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Curves.fastOutSlowIn,
        reverseCurve: Curves.fastOutSlowIn.flipped,
      );

      // Entrada desde la derecha / salida con back hacia la derecha.
      Widget result = SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(enterProgress),
        child: enter == NavTransition.parallax
            ? FadeTransition(opacity: enterProgress, child: child)
            : child,
      );

      // Salida hacia la izquierda cuando otra pantalla se apila encima.
      final exitDx = exit == NavTransition.parallax ? -1 / 3 : -1.0;
      result = SlideTransition(
        position: Tween<Offset>(
          begin: Offset.zero,
          end: Offset(exitDx, 0),
        ).animate(exitProgress),
        child: exit == NavTransition.parallax
            ? FadeTransition(
                opacity: Tween<double>(begin: 1, end: 0).animate(exitProgress),
                child: result,
              )
            : result,
      );
      return result;
    },
  );
}
