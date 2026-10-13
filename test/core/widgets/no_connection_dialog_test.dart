import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/widgets/no_connection_dialog.dart';

Widget _host({required bool restored, required VoidCallback onDismiss}) =>
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: NoConnectionDialog(
            isConnectionRestored: restored,
            onDismiss: onDismiss,
          ),
        ),
      ),
    );

void main() {
  testWidgets('muestra título, cuerpo y botón con los textos exactos del Kotlin',
      (tester) async {
    await tester.pumpWidget(_host(restored: false, onDismiss: () {}));

    expect(find.text('No estás conectado a internet'), findsOneWidget);
    expect(
      find.text(
        'Señor(a) ciudadano. Para un correcto funcionamiento de nuestra App es '
        'necesario estar conectado a internet, por favor verifique su conexión '
        'y vuelva a intentarlo.',
      ),
      findsOneWidget,
    );
    expect(find.text('Entendido'), findsOneWidget);
  });

  testWidgets(
      'el botón "Entendido" está deshabilitado si no hay conexión restaurada',
      (tester) async {
    await tester.pumpWidget(_host(restored: false, onDismiss: () {}));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('con conexión restaurada, tocar "Entendido" llama onDismiss una vez',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(_host(restored: true, onDismiss: () => calls++));

    await tester.tap(find.text('Entendido'));
    await tester.pump();

    expect(calls, 1);
  });
}
