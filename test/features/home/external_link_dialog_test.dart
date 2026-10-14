import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/widgets/important_alert_dialog.dart';
import 'package:tramiapp_flutter/features/home/application/main_viewmodel.dart';
import 'package:tramiapp_flutter/features/home/presentation/widgets/external_link_dialog.dart';

/// Aviso de sitio externo (`MainScreen.kt`, `showExternalLinkDialog`): con
/// `showWarning` espera 3 s, abre la URL una sola vez y se cierra; sin él abre
/// directo.

const _url = 'https://portal.example.gov.co/tramite';

Future<List<String>> _pumpAndOpen(
  WidgetTester tester,
  PendingUrl pending,
) async {
  final opened = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => openPendingUrl(
              context,
              pending,
              opener: (url) async {
                opened.add(url);
                return true;
              },
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  await tester.pump();
  return opened;
}

void main() {
  testWidgets('showWarning: aviso, abre una vez a los 3 s y se cierra',
      (tester) async {
    final opened =
        await _pumpAndOpen(tester, const PendingUrl(_url, showWarning: true));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Aviso Importante'), findsOneWidget);
    expect(find.text('redirigiendo...'), findsOneWidget);
    expect(opened, isEmpty);

    // No se puede cerrar mientras espera: ni tocando fuera ni con Atrás.
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.byType(ImportantAlertDialog), findsOneWidget);
    expect(opened, isEmpty);

    await tester.pump(const Duration(milliseconds: 2700));
    expect(opened, [_url]);

    // El cierre anima; luego ya no está y no se vuelve a abrir.
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ImportantAlertDialog), findsNothing);
    await tester.pump(const Duration(seconds: 5));
    expect(opened, [_url]);
  });

  testWidgets('sin showWarning: abre en seguida y sin diálogo', (tester) async {
    final opened =
        await _pumpAndOpen(tester, const PendingUrl(_url, showWarning: false));

    expect(opened, [_url]);
    expect(find.byType(ImportantAlertDialog), findsNothing);
  });
}
