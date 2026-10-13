import 'package:connectivity_plus/connectivity_plus.dart';

/// Estado de red simplificado (port de `ConnectivityObserver.Status`).
///
/// El original distingue `Available/Unavailable/Losing/Lost`, pero solo
/// reacciona a "Available vs. el resto"; `connectivity_plus` no expone
/// `Losing/Lost`, así que bastan dos estados.
enum ConnectivityStatus { available, unavailable }

/// Una lista vacía o que solo contiene `none` equivale a sin conexión.
ConnectivityStatus statusFromResults(List<ConnectivityResult> results) {
  final hasNetwork = results.any((r) => r != ConnectivityResult.none);
  return hasNetwork
      ? ConnectivityStatus.available
      : ConnectivityStatus.unavailable;
}
