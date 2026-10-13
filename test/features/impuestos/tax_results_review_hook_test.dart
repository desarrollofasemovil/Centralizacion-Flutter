import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/municipality/municipality_repository.dart';
import 'package:tramiapp_flutter/core/review/review_prompt_service.dart';
import 'package:tramiapp_flutter/features/impuestos/domain/tax.dart';
import 'package:tramiapp_flutter/features/impuestos/presentation/respuesta_consulta_screen.dart';

import '../../support/spy_review_prompt_service.dart';

const _tax = Tax(
  entity: 'Alcaldía',
  entityCode: '001',
  document: '123',
  name: 'Ana',
  taxName: 'Predial',
  taxId: 1,
  value: 1000,
  invoice: 'F-1',
  reference: 'R-1',
  dueDate: '2099-12-31',
  queryField: 'documento',
);

Future<SpyReviewPromptService> _pumpResults(
  WidgetTester tester, {
  required List<Tax> taxes,
}) async {
  final spy = SpyReviewPromptService();
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/results'),
            child: const Text('consultar'),
          ),
        ),
      ),
      GoRoute(
        path: '/results',
        builder: (_, _) =>
            TaxResultsScreen(municipalityId: 1, taxes: taxes, email: ''),
      ),
      GoRoute(path: '/history', builder: (_, _) => const Placeholder()),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        reviewPromptServiceProvider.overrideWithValue(spy),
        municipalityProvider.overrideWith(
          (ref, id) => Completer<MunicipalityDTO>().future,
        ),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.tap(find.text('consultar'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
  return spy;
}

void main() {
  testWidgets('consulta con facturas: al volver atrás se pide la reseña', (
    tester,
  ) async {
    final spy = await _pumpResults(tester, taxes: const [_tax]);
    expect(find.text('Facturas Encontradas'), findsOneWidget);
    expect(spy.moments, isEmpty, reason: 'no mientras revisa o paga');

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('consultar'), findsOneWidget);
    expect(spy.moments, [ReviewTrigger.taxQueryResults]);
  });

  testWidgets('sin facturas: volver atrás no pide la reseña', (tester) async {
    final spy = await _pumpResults(tester, taxes: const []);

    final navigator = tester.state<NavigatorState>(find.byType(Navigator));
    await navigator.maybePop();
    await tester.pump(const Duration(seconds: 1));

    expect(spy.moments, isEmpty);
  });

  testWidgets(
    'salir de resultados por navegación (go, p. ej. tras pagar) no la pide',
    (tester) async {
      final spy = await _pumpResults(tester, taxes: const [_tax]);

      GoRouter.of(
        tester.element(find.text('Facturas Encontradas')),
      ).go('/history');
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(Placeholder), findsOneWidget);
      expect(spy.moments, isEmpty);
    },
  );
}
