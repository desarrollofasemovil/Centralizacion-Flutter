import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';
import 'package:tramiapp_flutter/features/soporte/presentation/help_screen.dart';
import 'package:tramiapp_flutter/features/tutorial/application/tutorial_providers.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_config.dart';

class _NoSession extends SessionNotifier {
  @override
  UserDTO? build() => null;
}

Future<void> _pump(WidgetTester tester, {TutorialConfig? config}) async {
  final router = GoRouter(
    initialLocation: '/help',
    routes: [
      GoRoute(
        path: '/help',
        builder: (_, _) => const HelpScreen(
          municipalityId: 81,
          municipality: 'Alcaldía de Rionegro',
          portal: 'https://rionegro.gov.co',
        ),
      ),
      GoRoute(
        path: AppRoutes.tutorial,
        builder: (_, state) => Text(
          'tutorial ${state.pathParameters['id']} '
          '${(state.extra! as TutorialOrigin).value}',
        ),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionProvider.overrideWith(_NoSession.new),
        if (config != null) tutorialConfigProvider.overrideWithValue(config),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('«Ver tutorial de la app» abre el tutorial de esta alcaldía', (
    tester,
  ) async {
    await _pump(tester, config: const TutorialConfig());
    expect(find.text('NUEVO'), findsOneWidget);

    await tester.tap(find.text('Ver tutorial de la app'));
    await tester.pumpAndSettle();
    expect(find.text('tutorial 81 ayuda'), findsOneWidget);
  });

  testWidgets('con el interruptor apagado no aparece', (tester) async {
    await _pump(tester, config: const TutorialConfig(enabled: false));
    expect(find.text('Ver tutorial de la app'), findsNothing);
  });

  testWidgets('sin Remote Config (Firebase sin iniciar) tampoco', (
    tester,
  ) async {
    await _pump(tester);
    expect(find.text('Ver tutorial de la app'), findsNothing);
  });
}
