import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tramiapp_flutter/app.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_observer.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_status.dart';
import 'package:tramiapp_flutter/core/connectivity/no_connection_notifier.dart';
import 'package:tramiapp_flutter/core/flavor/flavor_config.dart';
import 'package:tramiapp_flutter/core/flavor/flavors.dart';
import 'package:tramiapp_flutter/core/storage/user_preferences.dart';
import 'package:tramiapp_flutter/features/onboarding/presentation/splash_screen.dart';

class _FakeObserver implements ConnectivityObserver {
  _FakeObserver(this._value);

  ConnectivityStatus _value;
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  void emit(ConnectivityStatus status) {
    _value = status;
    _controller.add(status);
  }

  @override
  Future<ConnectivityStatus> current() async => _value;

  @override
  Stream<ConnectivityStatus> observe() async* {
    yield _value;
    yield* _controller.stream;
  }
}

class _FailingObserver implements ConnectivityObserver {
  @override
  Future<ConnectivityStatus> current() async => throw StateError('plugin');

  @override
  Stream<ConnectivityStatus> observe() => Stream.error(StateError('plugin'));
}

const _welcomeKey = Key('welcome');
const _title = 'No estás conectado a internet';

Future<void> _pumpSplash(
  WidgetTester tester,
  ConnectivityObserver observer,
) async {
  FlavorConfig.instance = flavorMunicipios;
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: '/welcome',
        builder: (_, _) => const Placeholder(key: _welcomeKey),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        connectivityObserverProvider.overrideWithValue(observer),
        // Debounce largo: lo que se vea a los 3600 ms lo provocó el Splash.
        noConnectionDebounceProvider
            .overrideWithValue(const Duration(minutes: 10)),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => GlobalStatusOverlay(
          backButtonDispatcher: router.backButtonDispatcher,
          child: child!,
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _disposeApp(WidgetTester tester) =>
    tester.pumpWidget(const SizedBox.shrink());

void main() {
  testWidgets('sin red a los 3600 ms: no navega y el diálogo queda visible',
      (tester) async {
    await _pumpSplash(tester, _FakeObserver(ConnectivityStatus.unavailable));

    await tester.pump(const Duration(milliseconds: 3500));
    expect(find.text(_title), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.text(_title), findsOneWidget);
    expect(find.byKey(_welcomeKey), findsNothing);
    await _disposeApp(tester);
  });

  testWidgets(
      'al volver la red: el diálogo se cierra y navega a la pantalla inicial',
      (tester) async {
    final observer = _FakeObserver(ConnectivityStatus.unavailable);
    await _pumpSplash(tester, observer);
    await tester.pump(const Duration(milliseconds: 3700));
    expect(find.text(_title), findsOneWidget);

    observer.emit(ConnectivityStatus.available);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(_title), findsNothing);
    expect(find.byKey(_welcomeKey), findsOneWidget);
    await _disposeApp(tester);
  });

  testWidgets('con red: navega a los 3600 ms como antes', (tester) async {
    await _pumpSplash(tester, _FakeObserver(ConnectivityStatus.available));

    await tester.pump(const Duration(milliseconds: 3500));
    expect(find.byKey(_welcomeKey), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();

    expect(find.byKey(_welcomeKey), findsOneWidget);
    expect(find.text(_title), findsNothing);
    await _disposeApp(tester);
  });

  testWidgets('si el stream de conectividad falla, navega igual',
      (tester) async {
    await _pumpSplash(tester, _FailingObserver());

    await tester.pump(const Duration(milliseconds: 3600));
    await tester.pump();

    expect(find.byKey(_welcomeKey), findsOneWidget);
    expect(find.text(_title), findsNothing);
    await _disposeApp(tester);
  });
}
