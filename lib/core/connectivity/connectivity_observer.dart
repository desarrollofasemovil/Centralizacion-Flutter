import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_status.dart';

/// Port de `data/network/ConnectivityObserver.kt`.
abstract class ConnectivityObserver {
  /// Estado actual y cambios posteriores, sin duplicados consecutivos
  /// (equivale al `distinctUntilChanged()` del Kotlin).
  Stream<ConnectivityStatus> observe();

  Future<ConnectivityStatus> current();
}

class PlatformConnectivityObserver implements ConnectivityObserver {
  PlatformConnectivityObserver(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<ConnectivityStatus> current() async =>
      statusFromResults(await _connectivity.checkConnectivity());

  @override
  Stream<ConnectivityStatus> observe() => _changes().distinct();

  Stream<ConnectivityStatus> _changes() async* {
    yield await current();
    yield* _connectivity.onConnectivityChanged.map(statusFromResults);
  }
}

final connectivityObserverProvider = Provider<ConnectivityObserver>(
  (ref) => PlatformConnectivityObserver(Connectivity()),
);

final connectivityStatusProvider = StreamProvider<ConnectivityStatus>(
  (ref) => ref.watch(connectivityObserverProvider).observe(),
);
