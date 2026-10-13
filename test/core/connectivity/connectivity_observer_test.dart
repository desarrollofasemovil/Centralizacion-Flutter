import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_observer.dart';
import 'package:tramiapp_flutter/core/connectivity/connectivity_status.dart';

class _FakeConnectivity implements Connectivity {
  _FakeConnectivity({required this.initial, required this.changes});

  final List<ConnectivityResult> initial;
  final List<List<ConnectivityResult>> changes;

  @override
  Future<List<ConnectivityResult>> checkConnectivity() async => initial;

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      Stream.fromIterable(changes);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    '[wifi, mobile] => available',
    () => expect(
      statusFromResults([ConnectivityResult.wifi, ConnectivityResult.mobile]),
      ConnectivityStatus.available,
    ),
  );

  test(
    '[none] => unavailable',
    () => expect(
      statusFromResults([ConnectivityResult.none]),
      ConnectivityStatus.unavailable,
    ),
  );

  test(
    '[] => unavailable',
    () => expect(statusFromResults(const []), ConnectivityStatus.unavailable),
  );

  test('observe(): estado inicial y cambios, sin duplicados consecutivos',
      () async {
    final fake = _FakeConnectivity(
      initial: [ConnectivityResult.wifi],
      changes: [
        [ConnectivityResult.wifi],
        [ConnectivityResult.none],
        [ConnectivityResult.none],
        [ConnectivityResult.mobile],
      ],
    );

    final emitted = await PlatformConnectivityObserver(fake)
        .observe()
        .take(3)
        .toList();

    expect(emitted, [
      ConnectivityStatus.available,
      ConnectivityStatus.unavailable,
      ConnectivityStatus.available,
    ]);
  });
}
