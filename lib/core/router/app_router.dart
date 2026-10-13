import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../flavor/flavor_config.dart';
import '../storage/user_preferences.dart';
import '../municipality/municipality_repository.dart';
import 'app_routes.dart';
import 'app_transitions.dart';
import 'placeholders.dart';

import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/municipality/presentation/select_municipality_screen.dart';
import '../../features/auth/presentation/signup_wizard.dart';
import '../../features/auth/presentation/recovery_password_screen.dart';
import '../../features/auth/presentation/change_password_reset_screen.dart';
import '../../features/home/presentation/main_screen.dart';
import '../../features/home/presentation/main_screen_skeleton.dart';
import '../../features/news/presentation/news_screen.dart';

// PQRD
import '../../features/pqrd/presentation/pqrds_choice_screen.dart';
import '../../features/pqrd/presentation/pqrd_identificacion_screen.dart';
import '../../features/pqrd/presentation/pqrd_anonima_screen.dart';

// Impuestos
import '../../features/impuestos/domain/tax.dart';
import '../../features/impuestos/presentation/consulta_impuesto_screen.dart';
import '../../features/impuestos/presentation/respuesta_consulta_screen.dart';

// Certificados
import '../../features/certificados/presentation/certificates_wizard.dart';

// Servicios Publicos
import '../../features/servicios_publicos/presentation/public_services_menu_screen.dart';
import '../../features/servicios_publicos/presentation/select_entity_screen.dart';
import '../../features/servicios_publicos/presentation/barcode_instructions_screen.dart';
import '../../features/servicios_publicos/presentation/scanner_screen.dart';
import '../../features/servicios_publicos/presentation/public_services_form_screen.dart';
import '../../features/servicios_publicos/presentation/public_services_history_screen.dart';
import '../../features/servicios_publicos/presentation/public_services_bill_details_screen.dart';

// Pagos
import '../../features/pagos/presentation/psv_wizard.dart';
import '../../features/pagos/presentation/payment_processing_screen.dart';

// Cursos
import '../../features/cursos/application/courses_notifier.dart';
import '../../features/cursos/presentation/courses_screen.dart';

// Venues (Escenarios deportivos)
import '../../features/venues/application/venues_notifier.dart';
import '../../features/venues/presentation/venues_screen.dart';

// Soporte / Ayuda
import '../../features/soporte/presentation/help_screen.dart';

// Perfil / Ajustes
import '../../features/perfil/presentation/user_settings_screen.dart';
import '../../features/perfil/presentation/edit_profile_screen.dart';

// Historial Pagos
import '../../features/historial_pagos/presentation/history_pay_screen.dart';

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

/// `GoRoute` con las transiciones de Compose (ver [appPage]).
GoRoute _route({
  required String path,
  required Widget Function(BuildContext, GoRouterState) builder,
  NavTransition enter = NavTransition.standard,
  NavTransition exit = NavTransition.standard,
}) {
  return GoRoute(
    path: path,
    pageBuilder: (context, state) =>
        appPage(state, builder(context, state), enter: enter, exit: exit),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashScreen()),
      _route(path: AppRoutes.welcome, builder: (_, _) => const WelcomeScreen()),
      _route(
        path: AppRoutes.selectMunicipality,
        builder: (context, state) {
          final departmentId =
              int.tryParse(state.pathParameters['departmentId'] ?? '') ?? 0;
          return SelectMunicipalityScreen(departmentId: departmentId);
        },
      ),
      _route(
        path: AppRoutes.signup,
        enter: NavTransition.parallax,
        exit: NavTransition.parallax,
        builder: (_, _) => const SignUpScreen(),
      ),
      _route(
        path: AppRoutes.recoverPassword,
        builder: (_, _) => const RecoveryPasswordScreen(),
      ),
      _route(
        path: AppRoutes.changePasswordReset,
        builder: (_, _) => const ChangePasswordResetScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
          return AlcaldiasScope(municipalityId: id, child: child);
        },
        routes: [
          _route(
            path: AppRoutes.municipality,
            exit: NavTransition.parallax,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return _MainScreenContainer(municipalityId: id);
            },
          ),
          _route(
            path: AppRoutes.news,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return _NewsScreenContainer(municipalityId: id);
            },
          ),
          // PQRD sub-routes
          _route(
            path: AppRoutes.pqrd,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PqrdsChoiceScreen(municipalityId: id);
            },
          ),
          _route(
            path: '/municipality/:id/pqrd/identificada',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PqrdIdentificacionScreen(municipalityId: id);
            },
          ),
          _route(
            path: '/municipality/:id/pqrd/anonima',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PqrdAnonimaScreen(municipalityId: id);
            },
          ),
          // Impuestos sub-routes
          _route(
            path: AppRoutes.taxes,
            enter: NavTransition.parallax,
            exit: NavTransition.parallax,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              final taxId = extra?['taxId'] as int? ?? 1;
              final title = extra?['title'] as String? ?? 'Impuestos';
              final dataPolicyUrl = extra?['dataPolicyUrl'] as String? ?? '';
              final privacyPolicyUrl =
                  extra?['privacyPolicyUrl'] as String? ?? '';
              return ConsultaImpuestoScreen(
                municipalityId: id,
                taxId: taxId,
                title: title,
                dataPolicyUrl: dataPolicyUrl,
                privacyPolicyUrl: privacyPolicyUrl,
              );
            },
          ),
          _route(
            path: '/municipality/:id/taxes/results',
            enter: NavTransition.parallax,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              final taxes = extra?['taxes'] as List<Tax>? ?? [];
              final email = extra?['email'] as String? ?? '';
              return TaxResultsScreen(
                municipalityId: id,
                taxes: taxes,
                email: email,
              );
            },
          ),
          // Certificados sub-route
          _route(
            path: AppRoutes.certificados,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final entityCode = state.pathParameters['entityCode'] ?? '';
              final procedureId =
                  int.tryParse(state.pathParameters['procedureId'] ?? '') ?? 0;
              final integrationType =
                  state.pathParameters['integrationType'] ?? '';
              return CertificatesWizard(
                municipalityId: id,
                entityCode: entityCode,
                procedureId: procedureId,
                integrationType: integrationType,
              );
            },
          ),
          // Servicios Publicos sub-routes
          _route(
            path: AppRoutes.serviciosPublicosMenu,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PublicServicesMenuScreen(municipalityId: id);
            },
          ),
          _route(
            path: AppRoutes.serviciosPublicosSelectEntity,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return SelectEntityScreen(municipalityId: id);
            },
          ),
          _route(
            path: AppRoutes.serviciosPublicosInstructions,
            enter: NavTransition.parallax,
            exit: NavTransition.parallax,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return BarcodeInstructionsScreen(municipalityId: id);
            },
          ),
          _route(
            path: AppRoutes.serviciosPublicosScanner,
            enter: NavTransition.parallax,
            exit: NavTransition.parallax,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ScannerScreen(municipalityId: id);
            },
          ),
          _route(
            path: AppRoutes.serviciosPublicosForm,
            enter: NavTransition.parallax,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final factura = state.pathParameters['factura'] ?? '';
              final valor = state.pathParameters['valor'] ?? '';
              final fechaVencimiento =
                  state.pathParameters['fechaVencimiento'] ?? '';
              return PublicServicesFormScreen(
                municipalityId: id,
                factura: factura,
                valor: valor,
                fechaVencimiento: fechaVencimiento,
              );
            },
          ),
          _route(
            path: AppRoutes.serviciosPublicosHistory,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PublicServicesHistoryScreen(municipalityId: id);
            },
          ),
          _route(
            path: AppRoutes.serviciosPublicosBillDetails,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return PublicServicesBillDetailsScreen(
                municipalityId: id,
                billDetails: extra,
              );
            },
          ),
          // Pagos sub-routes
          _route(
            path: AppRoutes.pagosPsv,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              final taxId = extra?['taxId'] as int? ?? 0;
              final taxName = extra?['taxName'] as String? ?? '';
              final entityCode = extra?['entityCode'] as String? ?? '';
              final dataPolicyUrl = extra?['dataPolicyUrl'] as String? ?? '';
              final privacyPolicyUrl =
                  extra?['privacyPolicyUrl'] as String? ?? '';
              return PsvWizard(
                municipalityId: id,
                taxId: taxId,
                taxName: taxName,
                entityCode: entityCode,
                dataPolicyUrl: dataPolicyUrl,
                privacyPolicyUrl: privacyPolicyUrl,
              );
            },
          ),
          _route(
            path: AppRoutes.pagosProcessing,
            enter: NavTransition.parallax,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              final paymentUrl = extra?['paymentUrl'] as String? ?? '';
              return PaymentProcessingScreen(
                municipalityId: id,
                paymentUrl: paymentUrl,
              );
            },
          ),
          _route(
            path: AppRoutes.pagosHistory,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return HistoryPayScreen(municipalityId: id);
            },
          ),
          _route(
            path: AppRoutes.cursos,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              return CoursesScreen(
                param: CoursesParam(
                  municipalityId: id,
                  courseId: extra?['courseId'] as int? ?? 0,
                  municipalityEmail:
                      extra?['emailMunicipalities'] as String? ?? '',
                ),
              );
            },
          ),
          _route(
            path: AppRoutes.venues,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              return VenuesScreen(
                param: VenuesParam(
                  municipalityId: id,
                  venueId: extra?['venueId'] as int? ?? 0,
                  municipalityEmail:
                      extra?['emailMunicipalities'] as String? ?? '',
                ),
              );
            },
          ),
          _route(
            path: AppRoutes.help,
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return HelpScreen(
                municipality: extra?['municipality'] as String? ?? '',
                portal: extra?['portal'] as String? ?? '',
              );
            },
          ),
          _route(
            path: AppRoutes.settings,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return UserSettingsScreen(municipalityId: id);
            },
          ),
          _route(
            path: AppRoutes.editProfile,
            builder: (context, state) => const EditProfileScreen(),
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
    return async.when(
      data: (dto) => MainScreen(municipality: dto),
      loading: () => const MainScreenSkeleton(),
      error: (_, _) => const LoadingScreen(),
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
      orElse: () => const LoadingScreen(),
    );
  }
}
