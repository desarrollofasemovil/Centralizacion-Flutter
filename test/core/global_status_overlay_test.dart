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
const _title = 'No estás conectado a internet';

Future<void> _pump(
  WidgetTester tester, {
  required bool dialogVisible,
  AppStatus status = const AppStatus(),
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
        home: const Scaffold(body: SizedBox.expand(key: _contentKey)),
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

  testWidgets('tocar la barrera no descarta el diálogo', (tester) async {
    await _pump(tester, dialogVisible: true);

    await tester.tapAt(const Offset(5, 5));
    await tester.pump();

    expect(find.text(_title), findsOneWidget);
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
