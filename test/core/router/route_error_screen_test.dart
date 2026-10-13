import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/core/flavor/flavor_config.dart';
import 'package:tramiapp_flutter/core/flavor/flavors.dart';
import 'package:tramiapp_flutter/core/router/app_router.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';

const _broken = '/municipality/1/no-existe/de/verdad';

Future<({GoRouter router, ProviderContainer container})> _pumpBrokenRoute(
  WidgetTester tester,
) async {
  FlavorConfig.instance = flavorMunicipios;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  final router = container.read(routerProvider);

  // Antes del primer frame: el Router arranca directamente en la ruta rota.
  router.go(_broken);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return (router: router, container: container);
}

/// Ubicación a la que el router fue enviado. `GoRouter.state` no sirve aquí:
/// con una ruta que no matchea la lista de matches está vacía.
String _location(GoRouter router) =>
    router.routeInformationProvider.value.uri.path;

void main() {
  testWidgets('ruta desconocida: pantalla de error propia, sin redirección '
      'automática', (tester) async {
    final h = await _pumpBrokenRoute(tester);

    expect(find.text('No pudimos abrir esta pantalla.'), findsOneWidget);
    expect(find.text('Volver al inicio'), findsOneWidget);
    expect(_location(h.router), _broken);

    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('"Volver al inicio" va al destino de arranque', (tester) async {
    final h = await _pumpBrokenRoute(tester);
    final expected = computeStartDestination(
      sendToWelcome: false,
      prefs: h.container.read(userPreferencesProvider),
    );
    // Sin ubicación guardada ni `send_to_welcome`, el arranque es Welcome.
    expect(expected, AppRoutes.welcome);

    await tester.tap(find.text('Volver al inicio'));
    expect(_location(h.router), expected);

    // Se desmonta antes del siguiente frame: Welcome necesita Firebase, y lo
    // que se prueba aquí es a dónde navega el botón, no la pantalla destino.
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
