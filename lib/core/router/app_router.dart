import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../flavor/flavor_config.dart';
import '../storage/user_preferences.dart';
import '../municipality/municipality_repository.dart';
import 'app_routes.dart';
import 'placeholders.dart';

import '../../features/onboarding/presentation/welcome_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/municipality/presentation/select_municipality_screen.dart';
import '../../features/auth/presentation/signup_wizard.dart';
import '../../features/auth/presentation/recovery_password_screen.dart';
import '../../features/home/presentation/main_screen.dart';
import '../../features/news/presentation/news_screen.dart';

// PQRD
import '../../features/pqrd/presentation/pqrds_choice_screen.dart';
import '../../features/pqrd/presentation/pqrd_wizard.dart';

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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, _) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (_, _) => const WelcomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.selectMunicipality,
        builder: (context, state) {
          final departmentId =
              int.tryParse(state.pathParameters['departmentId'] ?? '') ?? 0;
          return SelectMunicipalityScreen(departmentId: departmentId);
        },
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
          // PQRD sub-routes
          GoRoute(
            path: AppRoutes.pqrd,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PqrdsChoiceScreen(municipalityId: id);
            },
          ),
          GoRoute(
            path: '/municipality/:id/pqrd/identificada',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PqrdWizard(municipalityId: id, isAnonymous: false);
            },
          ),
          GoRoute(
            path: '/municipality/:id/pqrd/anonima',
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PqrdWizard(municipalityId: id, isAnonymous: true);
            },
          ),
          // Impuestos sub-routes
          GoRoute(
            path: AppRoutes.taxes,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              final taxId = extra?['taxId'] as int? ?? 1;
              final title = extra?['title'] as String? ?? 'Impuestos';
              return ConsultaImpuestoScreen(
                municipalityId: id,
                taxId: taxId,
                title: title,
              );
            },
          ),
          GoRoute(
            path: '/municipality/:id/taxes/results',
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
          GoRoute(
            path: AppRoutes.certificados,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final entityCode = state.pathParameters['entityCode'] ?? '';
              final procedureId = int.tryParse(state.pathParameters['procedureId'] ?? '') ?? 0;
              final integrationType = state.pathParameters['integrationType'] ?? '';
              return CertificatesWizard(
                municipalityId: id,
                entityCode: entityCode,
                procedureId: procedureId,
                integrationType: integrationType,
              );
            },
          ),
          // Servicios Publicos sub-routes
          GoRoute(
            path: AppRoutes.serviciosPublicosMenu,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PublicServicesMenuScreen(municipalityId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.serviciosPublicosSelectEntity,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return SelectEntityScreen(municipalityId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.serviciosPublicosInstructions,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return BarcodeInstructionsScreen(municipalityId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.serviciosPublicosScanner,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return ScannerScreen(municipalityId: id);
            },
          ),
          GoRoute(
            path: AppRoutes.serviciosPublicosForm,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final factura = state.pathParameters['factura'] ?? '';
              final valor = state.pathParameters['valor'] ?? '';
              final fechaVencimiento = state.pathParameters['fechaVencimiento'] ?? '';
              return PublicServicesFormScreen(
                municipalityId: id,
                factura: factura,
                valor: valor,
                fechaVencimiento: fechaVencimiento,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.serviciosPublicosHistory,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return PublicServicesHistoryScreen(municipalityId: id);
            },
          ),
          GoRoute(
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
          GoRoute(
            path: AppRoutes.pagosPsv,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              final taxId = extra?['taxId'] as int? ?? 0;
              final taxName = extra?['taxName'] as String? ?? '';
              final entityCode = extra?['entityCode'] as String? ?? '';
              final dataPolicyUrl = extra?['dataPolicyUrl'] as String? ?? '';
              final privacyPolicyUrl = extra?['privacyPolicyUrl'] as String? ?? '';
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
          GoRoute(
            path: AppRoutes.pagosProcessing,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              final extra = state.extra as Map<String, dynamic>?;
              final paymentUrl = extra?['paymentUrl'] as String? ?? '';
              final tax = extra?['tax'] as Tax;
              return PaymentProcessingScreen(
                municipalityId: id,
                paymentUrl: paymentUrl,
                tax: tax,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.pagosHistory,
            builder: (context, state) {
              final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
              return HistoryPayScreen(municipalityId: id);
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
      orElse: () => const LoadingScreen(),
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

