import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connectivity_observer.dart';
import 'connectivity_status.dart';

/// Ventana de espera antes de mostrar el diálogo (Kotlin: `delay(3000)`).
/// Inyectable para que los tests no esperen 3 s reales.
final noConnectionDebounceProvider =
    Provider<Duration>((_) => const Duration(seconds: 3));

/// Visibilidad del diálogo "No estás conectado a internet" (port de
/// `MainActivityViewModel.kt:62-83`).
///
/// Cada emisión cancela el temporizador pendiente. `available` oculta el
/// diálogo de inmediato; `unavailable` lo muestra tras el debounce, salvo que
/// ya esté visible.
class NoConnectionNotifier extends Notifier<bool> {
  Timer? _timer;

  @override
  bool build() {
    ref.onDispose(_cancelTimer);
    ref.listen<AsyncValue<ConnectivityStatus>>(
      connectivityStatusProvider,
      (_, next) {
        final status = next.value;
        if (status != null) _onStatus(status);
      },
      fireImmediately: true,
    );
    return false;
  }

  void _onStatus(ConnectivityStatus status) {
    _cancelTimer();
    switch (status) {
      case ConnectivityStatus.available:
        state = false;
      case ConnectivityStatus.unavailable:
        if (state) return;
        _timer = Timer(ref.read(noConnectionDebounceProvider), () {
          state = true;
        });
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Muestra el diálogo sin debounce (lo usa el Splash).
  void show() {
    _cancelTimer();
    state = true;
  }

  void dismiss() {
    _cancelTimer();
    state = false;
  }
}

final noConnectionDialogProvider =
    NotifierProvider<NoConnectionNotifier, bool>(NoConnectionNotifier.new);
