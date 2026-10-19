import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:go_router/go_router.dart';
import 'package:tramiapp_flutter/core/router/app_routes.dart';
import 'package:tramiapp_flutter/core/router/safe_pop.dart';
import 'package:tramiapp_flutter/core/widgets/app_back_button.dart';
import 'package:tramiapp_flutter/core/widgets/top_bar_navigation.dart';
import 'package:tramiapp_flutter/features/pagos/application/payment_processing_notifier.dart';
import 'package:tramiapp_flutter/features/pagos/presentation/payment_processing_screen.dart';

const _id = 1;
const _home = 'HOME';
const _history = 'HISTORY';

/// Cuenta regresiva ya terminada y verificación que siempre navega.
class _ReadyProcessing extends PaymentProcessingNotifier {
  @override
  PaymentProcessingState build() =>
      const PaymentProcessingState(secondsRemaining: 0);

  @override
  Future<bool> onCheckStatusClick({
    required int municipalityId,
    required PaymentOrigin origin,
  }) async => true;
}

/// Mismo esquema que el router real: rutas del municipio como hermanas planas
/// dentro de un `ShellRoute`. History usa la barra compartida con su `onBack`
/// por defecto, igual que `HistoryPayScreen`.
GoRouter _router(String initialLocation) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(
      path: '/fallback',
      builder: (_, _) => const Scaffold(body: Text('FALLBACK')),
    ),
    GoRoute(
      path: '/solo',
      builder: (context, _) => Scaffold(
        body: TextButton(
          onPressed: () => context.popOrGo('/fallback'),
          child: const Text('volver'),
        ),
      ),
    ),
    ShellRoute(
      builder: (_, _, child) => child,
      routes: [
        GoRoute(
          path: AppRoutes.municipality,
          builder: (_, _) => const Scaffold(body: Text(_home)),
        ),
        GoRoute(
          path: AppRoutes.pagosProcessing,
          builder: (_, _) => const PaymentProcessingScreen(
            municipalityId: _id,
            paymentUrl: '',
          ),
        ),
        GoRoute(
          path: AppRoutes.pagosHistory,
          builder: (_, _) => const TopBarNavigationScaffold(
            iconAsset: 'assets/images/ico_calendar_history.svg',
            title: 'Historial de pagos',
            description: '',
            body: Text(_history),
          ),
        ),
      ],
    ),
  ],
);

Future<GoRouter> _pump(WidgetTester tester, String initialLocation) async {
  final router = _router(initialLocation);
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        paymentProcessingNotifierProvider.overrideWith(_ReadyProcessing.new),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await _settle(tester);
  return router;
}

/// Pagar → "Verificar estado del pago" → Historial.
Future<void> _processingToHistory(WidgetTester tester, GoRouter router) async {
  router.push(AppRoutes.pagosProcessingPath(_id));
  await _settle(tester);
  await tester.tap(find.text('Verificar estado del pago'));
  await _settle(tester);
  expect(find.text(_history), findsOneWidget);
}

/// Deja terminar las transiciones. No `pumpAndSettle`: el indicador de
/// `PaymentProcessingScreen` anima sin fin.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

List<String> _mockPlatform(WidgetTester tester) {
  final calls = <String>[];
  final messenger = tester.binding.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    calls.add(call.method);
    return null;
  });
  addTearDown(
    () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

void main() {
  group('procesamiento → Historial', () {
    testWidgets('la pila queda Home → History (se puede hacer pop)', (
      tester,
    ) async {
      final router = await _pump(tester, AppRoutes.municipalityPath(_id));
      await _processingToHistory(tester, router);

      expect(router.canPop(), isTrue);
    });

    testWidgets('el botón atrás de la barra vuelve a Home', (tester) async {
      final router = await _pump(tester, AppRoutes.municipalityPath(_id));
      await _processingToHistory(tester, router);

      await tester.tap(find.byType(AppBackButton));
      await _settle(tester);

      expect(find.text(_home), findsOneWidget);
    });

    testWidgets('el atrás del sistema vuelve a Home', (tester) async {
      final router = await _pump(tester, AppRoutes.municipalityPath(_id));
      await _processingToHistory(tester, router);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(find.text(_home), findsOneWidget);
    });
  });

  group('History como única página de la pila (llegada con go)', () {
    testWidgets('el botón atrás de la barra cae a la Home del municipio', (
      tester,
    ) async {
      final router = await _pump(tester, AppRoutes.pagosHistoryPath(_id));
      expect(router.canPop(), isFalse);

      await tester.tap(find.byType(AppBackButton));
      await _settle(tester);

      expect(find.text(_home), findsOneWidget);
    });

    testWidgets('el atrás del sistema va a Home en vez de cerrar la app', (
      tester,
    ) async {
      final calls = _mockPlatform(tester);
      await _pump(tester, AppRoutes.pagosHistoryPath(_id));

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(calls, isNot(contains('SystemNavigator.pop')));
      expect(find.text(_home), findsOneWidget);
    });
  });

  group('popOrGo', () {
    testWidgets('sin a dónde volver navega al fallback', (tester) async {
      await _pump(tester, '/solo');

      await tester.tap(find.text('volver'));
      await _settle(tester);

      expect(find.text('FALLBACK'), findsOneWidget);
    });

    testWidgets('con pila hace pop normal', (tester) async {
      final router = await _pump(tester, AppRoutes.municipalityPath(_id));
      router.push('/solo');
      await _settle(tester);

      await tester.tap(find.text('volver'));
      await _settle(tester);

      expect(find.text(_home), findsOneWidget);
      expect(find.text('FALLBACK'), findsNothing);
    });
  });
}
