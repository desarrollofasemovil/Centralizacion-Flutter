import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/widgets/top_bar_navigation.dart';

Future<void> _pump(
  WidgetTester tester, {
  required double bodyHeight,
  required bool onlyWhenOverflows,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: TopBarNavigationScaffold(
        iconAsset: 'assets/images/ico_calendar_history.svg',
        title: 'Historial de pagos',
        description: 'Desliza hacia abajo.',
        onBack: () {},
        onRefresh: () async {},
        collapseOnlyWhenContentOverflows: onlyWhenOverflows,
        body: SizedBox(height: bodyHeight),
      ),
    ),
  );
}

double _maxScroll(WidgetTester tester) => tester
    .state<ScrollableState>(find.byType(Scrollable))
    .position
    .maxScrollExtent;

void main() {
  testWidgets('por defecto, aun con cuerpo corto hay recorrido para recoger', (
    tester,
  ) async {
    await _pump(tester, bodyHeight: 50, onlyWhenOverflows: false);

    expect(_maxScroll(tester), greaterThan(0));
  });

  testWidgets('con la opción activa y cuerpo corto no hay scroll', (
    tester,
  ) async {
    await _pump(tester, bodyHeight: 50, onlyWhenOverflows: true);

    expect(_maxScroll(tester), 0);

    await tester.drag(find.byType(Scrollable), const Offset(0, -300));
    await tester.pump();

    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      0,
    );
  });

  testWidgets('con la opción activa y cuerpo largo sí se desplaza', (
    tester,
  ) async {
    await _pump(tester, bodyHeight: 3000, onlyWhenOverflows: true);

    expect(_maxScroll(tester), greaterThan(0));

    await tester.drag(find.byType(Scrollable), const Offset(0, -300));
    await tester.pump();

    expect(
      tester.state<ScrollableState>(find.byType(Scrollable)).position.pixels,
      greaterThan(0),
    );
  });
}
