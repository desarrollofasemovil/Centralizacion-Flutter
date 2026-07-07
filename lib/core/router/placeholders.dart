import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../municipality/municipality_repository.dart';
import '../theme/app_theme.dart';
import '../theme/theme_mode_provider.dart';

// Pantallas placeholder de la Fase 1. Se reemplazan por las reales en la Fase 2
// (ver FRONTEND §5). Aquí solo validan navegación, arranque y theming dinámico.

/// Loader genérico mientras se resuelve la config del municipio (FRONTEND §1.1:
/// "state.isLoading muestra un CircularProgressIndicator sobre primarycolor").
/// No confundir con el SplashScreen real (onboarding/presentation/splash_screen.dart),
/// que es la pantalla de arranque con el GIF de carga.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).colorScheme.primary,
    body: const Center(child: CircularProgressIndicator(color: Colors.white)),
  );
}

/// Orquestador del municipio: carga la config una vez y aplica el `ThemeData`
/// dinámico al subárbol (equivalente a `AlcaldiasStateWrapper`, FRONTEND §2.1).
class AlcaldiasScope extends ConsumerWidget {
  const AlcaldiasScope({
    required this.municipalityId,
    required this.child,
    super.key,
  });

  final int municipalityId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(themeIsDarkProvider);
    final async = ref.watch(municipalityProvider(municipalityId));

    return async.when(
      // Durante la carga renderizamos el `child` con el tema neutro para que cada
      // pantalla (p. ej. la Home) muestre su propio esqueleto en vez de un spinner
      // genérico. Sin esto, este `loading` tapaba el `MainScreenSkeleton`.
      loading: () => Theme(
        data: buildInicialTheme(dark: dark),
        child: child,
      ),
      error: (e, _) => Theme(
        data: buildInicialTheme(dark: dark),
        child: _ErrorMunicipalityScreen(message: e.toString()),
      ),
      data: (dto) => Theme(
        data: buildAlcaldiasTheme(designFromMunicipality(dto), dark: dark),
        child: child,
      ),
    );
  }
}

class _ErrorMunicipalityScreen extends StatelessWidget {
  const _ErrorMunicipalityScreen({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Error')),
    body: Center(child: Text('No se pudo cargar el municipio.\n$message')),
  );
}
