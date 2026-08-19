import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vector_graphics_compiler/vector_graphics_compiler.dart' as vg;
import 'package:tramiapp_flutter/core/widgets/app_back_button.dart';
import 'package:tramiapp_flutter/core/widgets/circles_decoration.dart';
import 'package:tramiapp_flutter/core/widgets/top_bar_navigation.dart';
import 'package:tramiapp_flutter/features/home/presentation/widgets/main_bottom_nav_bar.dart';

/// Cobertura de los componentes de UI compartidos que se unificaron al portar
/// `TopbarNavigation.kt`, el botón de retroceso circular y el adorno `circles`.
/// Verifica que se construyan sin excepciones y que los assets SVG existan
/// (una ruta mal escrita revienta en runtime, no en `flutter analyze`).
void main() {
  Widget host(Widget child, {Color primary = const Color(0xFF00539F)}) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
      ),
      home: child,
    );
  }

  // Los dos SVG se escribieron a mano portando `circles.xml` y
  // `ico_calendar_history.xml`; si el `pathData` de Android no fuese válido
  // como `d` de SVG, fallaría en runtime y no en el analizador.
  group('assets portados desde vector drawables', () {
    for (final asset in const [
      'assets/images/circles.svg',
      'assets/images/ico_calendar_history.svg',
    ]) {
      test('$asset es un SVG que flutter_svg puede compilar', () {
        final source = File(asset).readAsStringSync();
        // Los optimizadores requieren la librería nativa PathOps, que no se
        // carga en el VM de tests; se desactivan para probar solo el parseo.
        expect(
          () => vg.parse(
            source,
            enableMaskingOptimizer: false,
            enableClippingOptimizer: false,
            enableOverdrawOptimizer: false,
          ),
          returnsNormally,
        );
      });
    }
  });

  group('AppBackButton', () {
    testWidgets('estilo relleno: círculo primary con flecha onPrimary', (
      tester,
    ) async {
      var pulsado = false;
      await tester.pumpWidget(
        host(
          Scaffold(
            body: AppBackButton(onPressed: () => pulsado = true),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.arrow_back_ios_new);
      expect(icon.size, AppBackButton.iconSize);

      await tester.tap(find.byType(AppBackButton));
      expect(pulsado, isTrue);
    });

    testWidgets('estilo claro: fondo blanco', (tester) async {
      await tester.pumpWidget(
        host(
          Scaffold(
            body: AppBackButton(
              onPressed: () {},
              style: AppBackButtonStyle.light,
            ),
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(
          of: find.byType(AppBackButton),
          matching: find.byType(Material),
        ),
      );
      expect(material.color, Colors.white);
    });
  });

  testWidgets('CirclesDecoration se dibuja sin romper el Stack', (tester) async {
    await tester.pumpWidget(
      host(
        const Scaffold(
          body: Stack(
            children: [SizedBox.expand(), CirclesDecoration.home()],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(CirclesDecoration), findsOneWidget);
  });

  testWidgets('TopBarNavigationScaffold muestra título, descripción y back', (
    tester,
  ) async {
    var volvio = false;
    await tester.pumpWidget(
      host(
        TopBarNavigationScaffold(
          iconAsset: 'assets/images/ico_calendar_history.svg',
          title: 'Historial de pagos',
          description: 'Desliza hacia abajo y actualiza el estado.',
          onBack: () => volvio = true,
          body: const SizedBox(height: 400),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Historial de pagos'), findsWidgets);
    expect(find.text('Desliza hacia abajo y actualiza el estado.'), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    expect(volvio, isTrue);
  });

  testWidgets('MainBottomNavBar usa los 4 destinos de la marca', (tester) async {
    await tester.pumpWidget(
      host(
        Scaffold(
          bottomNavigationBar: MainBottomNavBar(
            selectedRoute: 'inicio',
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    for (final label in ['Inicio', 'Noticias', 'Portal', 'Historial']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}
