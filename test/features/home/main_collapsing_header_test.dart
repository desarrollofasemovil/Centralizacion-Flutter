import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/theme/design.dart';
import 'package:tramiapp_flutter/core/widgets/app_back_button.dart';
import 'package:tramiapp_flutter/features/home/presentation/widgets/main_header.dart';
import 'package:tramiapp_flutter/features/home/presentation/widgets/main_collapsing_header.dart';

Design _design(String name) =>
    Design.fromThemeHex(alcaldiaName: name, shieldUrl: '');

Future<MainHeaderDelegate> _pump(
  WidgetTester tester, {
  String name = 'Alcaldía de Prueba',
  String? departamento = 'Antioquia',
  bool isLoading = false,
  VoidCallback? onMenu,
}) async {
  late MainHeaderDelegate delegate;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            delegate = MainHeaderDelegate.measured(
              context,
              design: _design(name),
              departamento: departamento,
              isLoading: isLoading,
              onMenu: onMenu ?? () {},
              onBack: () {},
              topInset: 0,
              width: constraints.maxWidth,
            );
            return CustomScrollView(
              slivers: [
                SliverPersistentHeader(pinned: true, delegate: delegate),
                const SliverToBoxAdapter(child: SizedBox(height: 2000)),
              ],
            );
          },
        ),
      ),
    ),
  );
  return delegate;
}

/// Alto pintado de la cabecera: un sliver no tiene `Size`, se mide el recorte
/// que la envuelve.
double _headerHeight(WidgetTester tester) => tester
    .getSize(
      find
          .descendant(
            of: find.byType(SliverPersistentHeader),
            matching: find.byType(ClipRect),
          )
          .first,
    )
    .height;

double _opacity(WidgetTester tester, Key key) =>
    tester.widget<Opacity>(find.byKey(key)).opacity;

void main() {
  testWidgets('desplegada: se ve el nombre grande y no el de la barra', (
    tester,
  ) async {
    await _pump(tester);

    expect(_opacity(tester, MainHeaderDelegate.expandedKey), 1);
    expect(_opacity(tester, MainHeaderDelegate.collapsedKey), 0);
  });

  testWidgets('al hacer scroll se recoge y deja nombre y departamento al lado '
      'del escudo', (tester) async {
    final delegate = await _pump(tester);
    expect(_headerHeight(tester), delegate.maxExtent);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();

    expect(_headerHeight(tester), delegate.minExtent);
    expect(_opacity(tester, MainHeaderDelegate.expandedKey), 0);
    expect(_opacity(tester, MainHeaderDelegate.collapsedKey), 1);
    expect(find.text('Alcaldía de Prueba'), findsNWidgets(2));
    // Recogida como Historial desplegado: queda la fila de botones y, debajo, el
    // escudo (64) con los textos; no una sola franja.
    expect(delegate.minExtent, AppBackButton.barHeight + 92);
    expect(tester.getSize(find.byType(MunicipalityShield)).width, 64);
    final shield = tester.getTopLeft(find.byType(MunicipalityShield));
    final name = tester.getTopLeft(find.text('Alcaldía de Prueba').last);
    expect(shield.dx, lessThan(name.dx));
    expect(shield.dy, greaterThan(AppBackButton.barHeight - 8));
    expect(find.text('Departamento de Antioquia'), findsNWidgets(2));
  });

  testWidgets('un nombre largo agranda la cabecera desplegada', (tester) async {
    final short = await _pump(tester, name: 'Medellín');
    final shortExtent = short.maxExtent;

    final long = await _pump(
      tester,
      name: 'Alcaldía Municipal de San Pedro de los Milagros del Norte',
    );

    expect(long.maxExtent, greaterThan(shortExtent));
  });

  testWidgets('sin departamento no reserva el renglón', (tester) async {
    final with_ = await _pump(tester);
    final without = await _pump(tester, departamento: null);

    expect(without.maxExtent, lessThan(with_.maxExtent));
    expect(find.textContaining('Departamento de'), findsNothing);
  });

  testWidgets('el menú sigue tocable con la cabecera recogida', (tester) async {
    var taps = 0;
    await _pump(tester, onMenu: () => taps++);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
    await tester.pump();

    await tester.tap(find.byIcon(Icons.menu));

    expect(taps, 1);
  });
}
