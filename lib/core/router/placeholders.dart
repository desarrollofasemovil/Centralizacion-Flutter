import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../municipality/municipality_repository.dart';
import '../storage/user_preferences.dart';
import '../theme/app_theme.dart';

// Pantallas placeholder de la Fase 1. Se reemplazan por las reales en la Fase 2
// (ver FRONTEND §5). Aquí solo validan navegación, arranque y theming dinámico.

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}



/// Orquestador del municipio: carga la config una vez y aplica el `ThemeData`
/// dinámico al subárbol (equivalente a `AlcaldiasStateWrapper`, FRONTEND §2.1).
class AlcaldiasScope extends ConsumerWidget {
  const AlcaldiasScope({required this.municipalityId, required this.child, super.key});

  final int municipalityId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = ref.watch(userPreferencesProvider).isDarkTheme();
    final async = ref.watch(municipalityProvider(municipalityId));

    return async.when(
      loading: () => Theme(
        data: buildInicialTheme(dark: dark),
        child: const SplashScreen(),
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


