import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../flavor/flavor_config.dart';
import '../remote_config/remote_config_service.dart';
import '../storage/user_preferences.dart';
import '../municipality/municipality_repository.dart';
import 'app_routes.dart';
import 'placeholders.dart';

import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/municipality/presentation/select_municipality_screen.dart';
import '../../features/auth/presentation/login_options_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_wizard.dart';
import '../../features/auth/presentation/recovery_password_screen.dart';
import '../../features/home/presentation/main_screen.dart';
import '../../features/news/presentation/news_screen.dart';

/// Decide la pantalla inicial (FRONTEND §1.1 / BACKEND §7.2):
/// - flavor individual (Manizales) → directo a su municipio fijo;
/// - `send_to_welcome` (Remote Config) → Welcome;
/// - ubicación guardada → directo al municipio guardado;
/// - si no → Welcome.
String computeStartDestination({
  required bool sendToWelcome,
  required UserPreferences prefs,
}) {
  final flavor = FlavorConfig.instance;
  if (flavor.isIndividual) {
    return AppRoutes.municipalityPath(flavor.fixedMunicipalityId!);
  }
  if (sendToWelcome) return AppRoutes.welcome;

  final loc = prefs.getSavedLocation();
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
            ? computeStartDestination(
                sendToWelcome: ref.read(sendToWelcomeProvider),
                prefs: ref.read(userPreferencesProvider),
              )
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
        path: AppRoutes.loginOptions,
        builder: (_, _) => const LoginOptionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, _) => const SignUpScreen(),
      ),
      GoRoute(
        path: AppRoutes.recoverPassword,
        builder: (_, _) => const RecoveryPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AlcaldiasScope(municipalityId: id, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.municipality,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return _MainScreenContainer(municipalityId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.news,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return _NewsScreenContainer(municipalityId: id);
            },
          ),
        ],
      ),
    ],
  );
});

class _MainScreenContainer extends ConsumerWidget {
  const _MainScreenContainer({required this.municipalityId});
  final int municipalityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(municipalityProvider(municipalityId));
    return async.maybeWhen(
      data: (dto) => MainScreen(municipality: dto),
      orElse: () => const SplashScreen(),
    );
  }
}

class _NewsScreenContainer extends ConsumerWidget {
  const _NewsScreenContainer({required this.municipalityId});
  final int municipalityId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(municipalityProvider(municipalityId));
    return async.maybeWhen(
      data: (dto) => NewsScreen(municipality: dto),
      orElse: () => const SplashScreen(),
    );
  }
}

