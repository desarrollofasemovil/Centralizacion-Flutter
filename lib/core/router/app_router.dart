import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../flavor/flavor_config.dart';
import '../remote_config/remote_config_service.dart';
import '../storage/user_preferences.dart';
import 'app_routes.dart';
import 'placeholders.dart';

/// Decide la pantalla inicial (FRONTEND §1.1 / BACKEND §7.2):
/// - flavor individual (Manizales) → directo a su municipio fijo;
/// - `send_to_welcome` (Remote Config) → Welcome;
/// - ubicación guardada → directo al municipio guardado;
/// - si no → Welcome.
String computeStartDestination(Ref ref) {
  final flavor = FlavorConfig.instance;
  if (flavor.isIndividual) {
    return AppRoutes.municipalityPath(flavor.fixedMunicipalityId!);
  }
  if (ref.read(sendToWelcomeProvider)) return AppRoutes.welcome;

  final loc = ref.read(userPreferencesProvider).getSavedLocation();
  if (loc.guardado && loc.municipalityId != 0) {
    return AppRoutes.municipalityPath(loc.municipalityId);
  }
  return AppRoutes.welcome;
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        redirect: (context, state) => state.matchedLocation == AppRoutes.splash
            ? computeStartDestination(ref)
            : null,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectMunicipality,
        builder: (_, _) => const SelectMunicipalityScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, _) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.municipality,
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AlcaldiasScope(municipalityId: id);
        },
      ),
    ],
  );
});
