import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/theme/app_theme.dart';
import 'package:tramiapp_flutter/core/theme/design.dart';
import 'package:tramiapp_flutter/core/widgets/confirmation_dialog.dart';
import 'package:tramiapp_flutter/core/widgets/important_alert_dialog.dart';
import 'package:tramiapp_flutter/core/widgets/timed_dialog.dart';

/// `ConfirmationDialog` e `ImportantAlertDialog` con el tema de un municipio:
/// cabecera con el color correcto, glifo de 50 dentro del círculo de 60 y los
/// botones / bloque de progreso que pide cada variante de `*.kt`.

const _municipalityPrimary = Color(0xFF00539F);

final _design = Design.fromThemeHex(
  alcaldiaName: 'Test',
  shieldUrl: '',
  primaryColor: '0xFF00539F',
  secondaryColor: '0xFF4364CD',
  secondaryColorBlack: '0xFFFFFFFF',
);

/// Abre [dialog] con `showDialog` desde un botón, como en la app. Con
/// [settle] en `false` no espera a que todo se detenga (un spinner gira para
/// siempre).
Future<void> _open(
  WidgetTester tester,
  Widget dialog, {
  bool settle = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAlcaldiasTheme(_design),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => dialog,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('abrir'));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }
}

/// Toca la barrera (fuera del diálogo).
Future<void> _tapOutside(WidgetTester tester) async {
  await tester.tapAt(const Offset(5, 5));
  await tester.pumpAndSettle();
}

Color? _headerColor(WidgetTester tester, Type dialogType) {
  final header = tester
      .widgetList<Container>(
        find.descendant(
          of: find.byType(dialogType),
          matching: find.byType(Container),
        ),
      )
      .first;
  return header.color;
}

void main() {
  group('ConfirmationDialog', () {
    testWidgets('con botones: cabecera del municipio, Cancelar y Cambiar',
        (tester) async {
      var confirmed = 0;
      var dismissed = 0;
      await _open(
        tester,
        ConfirmationDialog(
          title: 'Cambio de municipio',
          message: '¿Estás seguro que deseas cambiar de municipio?',
          icon: Icons.swap_horiz,
          confirmButtonText: 'Sí, Cambiar',
          dismissButtonText: 'Cancelar',
          onConfirm: () => confirmed++,
          onDismiss: () => dismissed++,
        ),
      );

      expect(_headerColor(tester, ConfirmationDialog), _municipalityPrimary);
      final icon = tester.widget<Icon>(find.byIcon(Icons.swap_horiz));
      expect(icon.size, 50);
      expect(icon.color, Colors.white);
      expect(find.widgetWithText(FilledButton, 'Sí, Cambiar'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Cancelar'), findsOneWidget);

      // Los botones van a la derecha (Arrangement.End): Cancelar antes que
      // Cambiar.
      final cancelX = tester.getCenter(find.text('Cancelar')).dx;
      final confirmX = tester.getCenter(find.text('Sí, Cambiar')).dx;
      expect(cancelX, lessThan(confirmX));

      await tester.tap(find.text('Sí, Cambiar'));
      await tester.tap(find.text('Cancelar'));
      expect(confirmed, 1);
      expect(dismissed, 1);
    });

    testWidgets('sin botones: no pinta ninguno y se cierra tocando fuera',
        (tester) async {
      await _open(
        tester,
        ConfirmationDialog(
          title: 'Inicio de sesión exitoso',
          message: 'Has iniciado sesión correctamente',
          icon: Icons.check_circle,
          onConfirm: () {},
          onDismiss: () {},
        ),
      );

      expect(find.text('Inicio de sesión exitoso'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ConfirmationDialog),
          matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
        ),
        findsNothing,
      );

      await _tapOutside(tester);
      expect(find.byType(ConfirmationDialog), findsNothing);
    });

    testWidgets('dentro de TimedDialog se cierra solo al cumplirse el tiempo',
        (tester) async {
      await _open(
        tester,
        TimedDialog(
          duration: const Duration(seconds: 2),
          child: ConfirmationDialog(
            title: 'Inicio de sesión exitoso',
            message: 'Has iniciado sesión correctamente',
            icon: Icons.check_circle,
            onConfirm: () {},
            onDismiss: () {},
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 1900));
      expect(find.byType(ConfirmationDialog), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationDialog), findsNothing);
    });
  });

  group('ImportantAlertDialog', () {
    testWidgets('con progreso y sin X: "redirigiendo..." y sin botón de cerrar',
        (tester) async {
      await _open(
        tester,
        ImportantAlertDialog(
          title: 'Aviso Importante',
          message: 'Estás a punto de ser redirigido a un sitio web externo a '
              'nuestra aplicación.',
          showProgressBar: true,
          hideDismissButton: true,
          onDismissRequest: () {},
        ),
        settle: false,
      );

      expect(_headerColor(tester, ImportantAlertDialog), const Color(0xFFE53935));
      final icon = tester.widget<Icon>(find.byIcon(Icons.priority_high_rounded));
      expect(icon.size, 50);
      expect(find.text('redirigiendo...'), findsOneWidget);
      final spinner = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      // El spinner toma el color del municipio, no el rojo de la cabecera.
      expect(spinner.color, _municipalityPrimary);
      expect(find.byIcon(Icons.close), findsNothing);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('con X y confirmar: ambos llaman a su callback', (tester) async {
      var dismissed = 0;
      var confirmed = 0;
      await _open(
        tester,
        ImportantAlertDialog(
          title: 'Eliminar Cuenta',
          message: 'Esta acción eliminará todos tus datos de forma permanente.',
          confirmButtonText: 'Confirmar',
          onDismissRequest: () => dismissed++,
          onConfirmRequest: () => confirmed++,
        ),
      );

      expect(find.text('redirigiendo...'), findsNothing);
      await tester.tap(find.byIcon(Icons.close));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Confirmar'));
      expect(dismissed, 1);
      expect(confirmed, 1);
    });
  });
}
