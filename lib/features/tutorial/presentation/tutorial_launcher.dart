import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/router/app_routes.dart';
import '../../auth/application/registration_draft.dart';
import '../../auth/presentation/login_bottom_sheet.dart';

/// Abre el tutorial sobre la pantalla actual y, si cerró con «Iniciar sesión»
/// o «Crear cuenta», sigue desde aquí: el tutorial ya no existe cuando hay que
/// mostrar la hoja de login o el registro.
Future<void> openTutorial(
  BuildContext context, {
  required int municipalityId,
  required TutorialOrigin origin,
}) async {
  final close = await context.push<TutorialClose>(
    AppRoutes.tutorialPath(municipalityId),
    extra: origin,
  );
  if (!context.mounted) return;
  switch (close) {
    case TutorialClose.login:
      await showLoginBottomSheet(context);
    case TutorialClose.signUp:
      // Igual que «Registrarse» de la hoja de login: registro manual, sin
      // borrador de Google.
      final container = ProviderScope.containerOf(context, listen: false);
      container.read(registrationDraftProvider.notifier).state = null;
      await container
          .read(analyticsServiceProvider)
          .logSignUpStarted(AuthMethod.email);
      if (context.mounted) await context.push(AppRoutes.signup);
    case TutorialClose.start || TutorialClose.later || null:
      break;
  }
}
