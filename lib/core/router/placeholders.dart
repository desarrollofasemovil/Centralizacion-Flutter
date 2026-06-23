import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/municipality_dto.dart';
import '../municipality/municipality_repository.dart';
import '../storage/user_preferences.dart';
import '../theme/app_theme.dart';
import 'app_routes.dart';

// Pantallas placeholder de la Fase 1. Se reemplazan por las reales en la Fase 2
// (ver FRONTEND §5). Aquí solo validan navegación, arranque y theming dinámico.

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenido')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Welcome / carrusel (placeholder Fase 2)'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => context.go(AppRoutes.selectMunicipality),
              child: const Text('Elegir municipio'),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectMunicipalityScreen extends StatelessWidget {
  const SelectMunicipalityScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecciona municipio')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Selector de municipio (placeholder Fase 2)'),
            const SizedBox(height: 12),
            // Demo: entra a un municipio de ejemplo para probar el theming.
            FilledButton(
              onPressed: () => context.go(AppRoutes.municipalityPath(1)),
              child: const Text('Entrar (id=1)'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Registro')),
        body: const Center(child: Text('Registro 3 pasos (placeholder Fase 2)')),
      );
}

/// Orquestador del municipio: carga la config una vez y aplica el `ThemeData`
/// dinámico al subárbol (equivalente a `AlcaldiasStateWrapper`, FRONTEND §2.1).
class AlcaldiasScope extends ConsumerWidget {
  const AlcaldiasScope({required this.municipalityId, super.key});

  final int municipalityId;

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
        child: _MainScreenPlaceholder(municipality: dto),
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

class _MainScreenPlaceholder extends StatelessWidget {
  const _MainScreenPlaceholder({required this.municipality});
  final MunicipalityDTO municipality;

  @override
  Widget build(BuildContext context) {
    final design = designFromMunicipality(municipality);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        title: Row(
          children: [
            if (design.escudoUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: design.escudoUrl,
                width: 32,
                height: 32,
                errorWidget: (_, _, _) => const Icon(Icons.location_city),
              ),
            const SizedBox(width: 8),
            Expanded(child: Text(design.nombreAlcaldia, overflow: TextOverflow.ellipsis)),
          ],
        ),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('entityCode: ${municipality.entityCode}'),
            Text('Trámites: ${municipality.municipalityProcedures.length}'),
            Text('Cursos: ${municipality.courses.length} · '
                'Escenarios: ${municipality.sportsFacilities.length}'),
            const SizedBox(height: 8),
            const Text('Home del municipio (placeholder Fase 2)'),
          ],
        ),
      ),
    );
  }
}
