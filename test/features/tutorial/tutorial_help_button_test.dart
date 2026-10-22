import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/tutorial/presentation/widgets/tutorial_help_button.dart';

const _badge = ValueKey('tutorial-help-badge');

Future<void> _pump(
  WidgetTester tester, {
  required bool highlighted,
  VoidCallback? onPressed,
  bool disableAnimations = false,
}) => tester.pumpWidget(
  MediaQuery(
    data: MediaQueryData(disableAnimations: disableAnimations),
    child: MaterialApp(
      home: Scaffold(
        body: Center(
          child: TutorialHelpButton(
            color: Colors.white,
            highlighted: highlighted,
            onPressed: onPressed ?? () {},
          ),
        ),
      ),
    ),
  ),
);

void main() {
  group('TutorialHelpButton', () {
    testWidgets('resaltado: muestra el punto y abre al tocar', (tester) async {
      var taps = 0;
      await _pump(tester, highlighted: true, onPressed: () => taps++);

      expect(find.byKey(_badge), findsOneWidget);
      expect(find.byIcon(Icons.question_mark_rounded), findsOneWidget);
      expect(find.byTooltip('Ver tutorial: cómo pagar'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.question_mark_rounded));
      expect(taps, 1);
    });

    testWidgets('ya visto: sin punto y sin latir', (tester) async {
      await _pump(tester, highlighted: false);

      expect(find.byKey(_badge), findsNothing);
      // Sin animación en curso, pumpAndSettle termina.
      await tester.pumpAndSettle();
    });

    testWidgets('sin animaciones del sistema no late, pero deja el punto', (
      tester,
    ) async {
      await _pump(tester, highlighted: true, disableAnimations: true);

      expect(find.byKey(_badge), findsOneWidget);
      await tester.pumpAndSettle();
    });
  });

  group('TutorialHelpHint', () {
    Future<void> pumpHint(
      WidgetTester tester, {
      required VoidCallback onPressed,
      required VoidCallback onClose,
      double textScale = 1,
    }) => tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: TutorialHelpHint(
                background: Colors.white,
                foreground: Colors.blue,
                onPressed: onPressed,
                onClose: onClose,
              ),
            ),
          ),
        ),
      ),
    );

    testWidgets('invita a ver el video; tocarlo abre y la × cierra', (
      tester,
    ) async {
      var opened = 0, closed = 0;
      await pumpHint(
        tester,
        onPressed: () => opened++,
        onClose: () => closed++,
      );

      expect(find.text('¿Necesitas ayuda?'), findsOneWidget);
      expect(find.text('Mira un video tutorial'), findsOneWidget);

      await tester.tap(find.text('Mira un video tutorial'));
      expect((opened, closed), (1, 0));

      await tester.tap(find.byTooltip('Cerrar aviso'));
      expect((opened, closed), (1, 1));
    });

    testWidgets('con letra al 200 % no se desborda', (tester) async {
      await pumpHint(tester, onPressed: () {}, onClose: () {}, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('UserPreferences', () {
    test('welcomeVideoSeen empieza en falso y se marca', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = UserPreferences(await SharedPreferences.getInstance());

      expect(prefs.welcomeVideoSeen(), isFalse);
      await prefs.markWelcomeVideoSeen();
      expect(prefs.welcomeVideoSeen(), isTrue);
    });

    test('welcomeHintDismissed empieza en falso y se marca', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = UserPreferences(await SharedPreferences.getInstance());

      expect(prefs.welcomeHintDismissed(), isFalse);
      await prefs.markWelcomeHintDismissed();
      expect(prefs.welcomeHintDismissed(), isTrue);
    });
  });
}
