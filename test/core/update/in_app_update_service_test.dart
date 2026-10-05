import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/update/in_app_update_service.dart';
import 'package:tramiapp_flutter/core/update/play_update_gateway.dart';

class _FakeGateway implements PlayUpdateGateway {
  PlayUpdateState state = PlayUpdateState.none;
  Object? checkError;
  Object? startError;
  Completer<void>? startGate;
  int checks = 0;
  int starts = 0;

  @override
  Future<PlayUpdateState> check() async {
    checks++;
    if (checkError != null) throw checkError!;
    return state;
  }

  @override
  Future<void> startImmediate() async {
    starts++;
    if (startGate != null) await startGate!.future;
    if (startError != null) throw startError!;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeGateway gateway;
  late InAppUpdateService service;

  setUp(() {
    gateway = _FakeGateway();
    service = InAppUpdateService(gateway, enabled: true);
  });

  group('InAppUpdateService', () {
    test('checkOnStart con available inicia el flujo una vez', () async {
      gateway.state = PlayUpdateState.available;
      await service.checkOnStart();
      expect(gateway.starts, 1);
    });

    test('checkOnStart sin actualización no inicia nada', () async {
      await service.checkOnStart();
      expect(gateway.checks, 1);
      expect(gateway.starts, 0);
    });

    test('checkOnStart con inProgress lo reanuda (arranque en frío a medias)',
        () async {
      gateway.state = PlayUpdateState.inProgress;
      await service.checkOnStart();
      expect(gateway.starts, 1);
    });

    test('onResume con inProgress lo reanuda', () async {
      gateway.state = PlayUpdateState.inProgress;
      await service.onResume();
      expect(gateway.starts, 1);
    });

    test('onResume con available NO inicia el flujo (sin bucle tras cancelar)',
        () async {
      gateway.state = PlayUpdateState.available;
      await service.onResume();
      expect(gateway.starts, 0);
    });

    test('check() lanza (app fuera de Play): se traga el error y no inicia',
        () async {
      gateway.checkError = PlatformException(code: 'ERROR_API_NOT_AVAILABLE');
      await service.checkOnStart();
      await service.onResume();
      expect(gateway.starts, 0);
    });

    test('startImmediate lanza: se traga el error', () async {
      gateway.state = PlayUpdateState.available;
      gateway.startError = PlatformException(code: 'boom');
      await expectLater(service.checkOnStart(), completes);
    });

    test('onResume durante un flujo activo no abre un segundo flujo',
        () async {
      gateway.state = PlayUpdateState.inProgress;
      gateway.startGate = Completer<void>();
      final first = service.checkOnStart();
      await Future<void>.delayed(Duration.zero);
      await service.onResume();
      gateway.startGate!.complete();
      await first;
      expect(gateway.starts, 1);
    });

    test('enabled == false: no llama al gateway', () async {
      gateway.state = PlayUpdateState.available;
      final disabled = InAppUpdateService(gateway, enabled: false);
      await disabled.checkOnStart();
      await disabled.onResume();
      expect(gateway.checks, 0);
      expect(gateway.starts, 0);
    });
  });

  group('InAppUpdateGateway (canal del plugin)', () {
    const channel = MethodChannel('de.ffuf.in_app_update/methods');
    late List<String> calls;

    void mockCheck({required int availability, required bool immediate}) {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'checkForUpdate') {
          return {
            'updateAvailability': availability,
            'immediateAllowed': immediate,
            'flexibleAllowed': false,
            'installStatus': 0,
            'packageName': 'com.tramites1cero1.centralizacion',
            'updatePriority': 0,
          };
        }
        return null;
      });
    }

    tearDown(() => TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null));

    final gw = InAppUpdateGateway();

    test('actualización disponible e inmediata permitida → available',
        () async {
      mockCheck(availability: 2, immediate: true);
      expect(await gw.check(), PlayUpdateState.available);
    });

    test('disponible pero inmediata NO permitida → none', () async {
      mockCheck(availability: 2, immediate: false);
      expect(await gw.check(), PlayUpdateState.none);
    });

    test('actualización iniciada por la app y a medias → inProgress',
        () async {
      mockCheck(availability: 3, immediate: true);
      expect(await gw.check(), PlayUpdateState.inProgress);
    });
  });
}
