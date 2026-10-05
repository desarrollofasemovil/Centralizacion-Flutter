import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/review/review_prompt_service.dart';
import 'package:tramiapp_flutter/features/pqrd/presentation/pqrd_result_dialogs.dart';

import '../../support/spy_review_prompt_service.dart';

/// `showPqrdSuccessDialog` lo usan PQRD anónima y con identificación.
Future<SpyReviewPromptService> _pump(
  WidgetTester tester,
  Future<void> Function(BuildContext) show,
) async {
  final spy = SpyReviewPromptService();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [reviewPromptServiceProvider.overrideWithValue(spy)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => show(context),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return spy;
}

void main() {
  testWidgets('PQRD radicada: al aceptar el ticket se pide la reseña',
      (tester) async {
    var dismissed = false;
    final spy = await _pump(
      tester,
      (c) => showPqrdSuccessDialog(c, 'T-123', onDismiss: () => dismissed = true),
    );
    expect(spy.moments, isEmpty, reason: 'no mientras se lee el ticket');

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(dismissed, isTrue);
    expect(spy.moments, [ReviewTrigger.pqrdFiled]);
  });

  testWidgets('error al radicar: no se pide la reseña', (tester) async {
    final spy = await _pump(tester, (c) => showPqrdErrorDialog(c, 'falló'));

    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();

    expect(spy.moments, isEmpty);
  });
}
