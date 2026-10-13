import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/app.dart';
import 'package:tramiapp_flutter/core/api/app_status.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_observer.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_status.dart';
import 'package:tramiapp_flutter/core/connectivity/no_connection_notifier.dart';

class _StubNoConnection extends NoConnectionNotifier {
  _StubNoConnection(this.initial);

  final bool initial;

  @override
  bool build() => initial;
}

class _StubAppStatus extends AppStatusNotifier {
  _StubAppStatus(this.initial);

  final AppStatus initial;

  @override
  AppStatus build() => initial;
}

const _contentKey = Key('contenido');

const _blocking = AppStatus(
  type: AppStatusType.serverError,
  title: 'Mantenimiento',
  isBlocking: true,
);

/// Página con estado propio: un contador que solo sobrevive si su `State`
/// no se desmonta.
class _CounterPage extends StatefulWidget {
  const _CounterPage();

  @override
  State<_CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<_CounterPage> {
  int taps = 0;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SizedBox.expand(
      key: _contentKey,
      child: Center(
        child: TextButton(
          onPressed: () => setState(() => taps++),
          child: Text('toques: $taps'),
        ),
      ),
    ),
  );
}

ProviderContainer _container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byKey(_contentKey)));
const _title = 'No estás conectado a internet';

Future<void> _pump(
  WidgetTester tester, {
  required bool dialogVisible,
  AppStatus status = const AppStatus(),
  FocusNode? focusNode,
  Widget? home,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        noConnectionDialogProvider
            .overrideWith(() => _StubNoConnection(dialogVisible)),
        appStatusProvider.overrideWith(() => _StubAppStatus(status)),
        connectivityStatusProvider
            .overrideWith((_) => Stream.value(ConnectivityStatus.unavailable)),
      ],
      child: MaterialApp(
        builder: (context, child) => GlobalStatusOverlay(
          backButtonDispatcher: RootBackButtonDispatcher(),
          child: child!,
        ),
        home:
            home ??
            Scaffold(
              body: SizedBox.expand(
                key: _contentKey,
                child: Center(child: TextField(focusNode: focusNode)),
              ),
            ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
      'diálogo visible: se ve el texto y el contenido de abajo sigue montado',
      (tester) async {
    await _pump(tester, dialogVisible: true);

    expect(find.text(_title), findsOneWidget);
    expect(find.byKey(_contentKey), findsOneWidget);
  });

  testWidgets('diálogo oculto: no aparece', (tester) async {
    await _pump(tester, dialogVisible: false);

    expect(find.text(_title), findsNothing);
    expect(find.byKey(_contentKey), findsOneWidget);
  });

  testWidgets(
      'estado bloqueante activo: no se muestra el diálogo aunque el notifier sea true',
      (tester) async {
    await _pump(
      tester,
      dialogVisible: true,
      status: const AppStatus(
        type: AppStatusType.serverError,
        title: 'Mantenimiento',
        isBlocking: true,
      ),
    );

    expect(find.text('Mantenimiento'), findsOneWidget);
    expect(find.text(_title), findsNothing);
  });

  testWidgets('con el diálogo visible el contenido de abajo pierde el foco',
      (tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await _pump(tester, dialogVisible: false, focusNode: focusNode);
    focusNode.requestFocus();
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);

    ProviderScope.containerOf(tester.element(find.byKey(_contentKey)))
        .read(noConnectionDialogProvider.notifier)
        .show();
    await tester.pump();

    expect(find.text(_title), findsOneWidget);
    expect(focusNode.hasFocus, isFalse);
  });

  testWidgets('tocar la barrera no descarta el diálogo', (tester) async {
    await _pump(tester, dialogVisible: true);

    await tester.tapAt(const Offset(5, 5));
    await tester.pump();

    expect(find.text(_title), findsOneWidget);
  });

  group('estado bloqueante sobre el router', () {
    testWidgets('la página de abajo conserva su State tras bloquear y limpiar',
        (tester) async {
      await _pump(tester, dialogVisible: false, home: const _CounterPage());
      await tester.tap(find.text('toques: 0'));
      await tester.pump();
      expect(find.text('toques: 1'), findsOneWidget);

      final container = _container(tester);
      container.read(appStatusProvider.notifier).updateStatus(_blocking);
      await tester.pump();
      expect(find.text('Mantenimiento'), findsOneWidget);
      // El router sigue montado debajo (antes se sustituía por la pantalla).
      expect(find.text('toques: 1'), findsOneWidget);

      container.read(appStatusProvider.notifier).clearStatus();
      await tester.pump();
      expect(find.text('Mantenimiento'), findsNothing);
      expect(find.text('toques: 1'), findsOneWidget);
    });

    testWidgets('los toques no llegan al contenido mientras bloquea',
        (tester) async {
      await _pump(
        tester,
        dialogVisible: false,
        status: _blocking,
        home: const _CounterPage(),
      );

      await tester.tapAt(tester.getCenter(find.text('toques: 0')));
      await tester.pump();

      expect(find.text('toques: 0'), findsOneWidget);
    });

    testWidgets(
        'tapa al diálogo sin conexión, que reaparece al levantarse el bloqueo',
        (tester) async {
      await _pump(tester, dialogVisible: true, status: _blocking);
      expect(find.text('Mantenimiento'), findsOneWidget);
      expect(find.text(_title), findsNothing);

      _container(tester).read(appStatusProvider.notifier).clearStatus();
      await tester.pump();

      expect(find.text('Mantenimiento'), findsNothing);
      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('el contenido de abajo pierde el foco', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await _pump(tester, dialogVisible: false, focusNode: focusNode);
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);

      _container(tester).read(appStatusProvider.notifier).updateStatus(_blocking);
      await tester.pump();

      expect(focusNode.hasFocus, isFalse);
    });
  });

  group('botón atrás del sistema', () {
    late List<String> platformCalls;

    setUp(() => platformCalls = []);

    void mockPlatform(WidgetTester tester) {
      final messenger = tester.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        platformCalls.add(call.method);
        return null;
      });
      addTearDown(
        () => messenger.setMockMethodCallHandler(SystemChannels.platform, null),
      );
    }

    testWidgets('con el diálogo visible no cierra la app ni lo descarta',
        (tester) async {
      mockPlatform(tester);
      await _pump(tester, dialogVisible: true);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
      expect(find.text(_title), findsOneWidget);
    });

    testWidgets('con el estado bloqueante no hace pop del router de abajo',
        (tester) async {
      mockPlatform(tester);
      await _pump(tester, dialogVisible: false, status: _blocking);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(platformCalls, isNot(contains('SystemNavigator.pop')));
      expect(find.text('Mantenimiento'), findsOneWidget);
    });

    testWidgets('sin diálogo, atrás sigue cerrando la app (control)',
        (tester) async {
      mockPlatform(tester);
      await _pump(tester, dialogVisible: false);

      await tester.binding.handlePopRoute();
      await tester.pump();

      expect(platformCalls, contains('SystemNavigator.pop'));
    });
  });
}
