import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/models/payment_history_dto.dart';
import '../../../core/review/review_prompt_service.dart';
import '../../auth/application/auth_providers.dart';

/// Segundos que se bloquea el botón "Verificar" (tiempo aprox. de un pago PSE).
const _verifyLockSeconds = 30;

/// Puerto de `PaymentProcessingUiState` (PaymentProcessingViewModel.kt).
class PaymentProcessingState {
  final int secondsRemaining;
  final bool isVerifying;

  const PaymentProcessingState({
    this.secondsRemaining = _verifyLockSeconds,
    this.isVerifying = false,
  });

  /// El botón de verificar solo se habilita cuando termina la cuenta regresiva.
  bool get isCheckEnabled => secondsRemaining == 0 && !isVerifying;

  PaymentProcessingState copyWith({int? secondsRemaining, bool? isVerifying}) {
    return PaymentProcessingState(
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isVerifying: isVerifying ?? this.isVerifying,
    );
  }
}

/// Puerto de `PaymentProcessingViewModel`: cuenta regresiva mientras el usuario
/// paga en la pasarela y sincronización de la última transacción al verificar.
class PaymentProcessingNotifier extends Notifier<PaymentProcessingState> {
  Timer? _timer;

  @override
  PaymentProcessingState build() {
    ref.onDispose(() => _timer?.cancel());
    _startCountdown();
    return const PaymentProcessingState();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.secondsRemaining - 1;
      state = state.copyWith(secondsRemaining: remaining < 0 ? 0 : remaining);
      if (remaining <= 0) timer.cancel();
    });
  }

  /// Acción «Verificar estado del pago»: sincroniza la última transacción
  /// registrada del usuario para que el Historial muestre el estado real.
  /// Devuelve `true` cuando la pantalla debe navegar al Historial.
  Future<bool> onCheckStatusClick() async {
    if (!state.isCheckEnabled) return false;
    state = state.copyWith(isVerifying: true);
    try {
      final userId = ref.read(sessionProvider)?.id;
      if (userId != null) {
        final api = ref.read(paymentHistoryApiServiceProvider);
        final history = await api.getHistoryPaymentByUser(userId);
        if (history.isNotEmpty) {
          final latestId = history
              .map((h) => h.id)
              .reduce((a, b) => a > b ? a : b);
          await api.syncPaymentStatus(latestId);
          // Reseña de la tienda si el pago quedó aprobado (FSM-59). El
          // Historial ya muestra el estado real; esta lectura solo decide eso.
          final synced = await api.getHistoryPaymentByUser(userId);
          final latest = synced.where((h) => h.id == latestId).firstOrNull;
          if (latest?.idStatusType == kPaymentStatusApproved) {
            unawaited(
              ref
                  .read(reviewPromptServiceProvider)
                  .onPositiveMoment(ReviewTrigger.paymentApproved),
            );
          }
        }
      }
    } catch (_) {
      // Igual que el runCatching del original: la verificación es best-effort;
      // el Historial mostrará el estado que tenga el backend.
    }
    state = state.copyWith(isVerifying: false);
    return true;
  }
}

final paymentProcessingNotifierProvider =
    NotifierProvider.autoDispose<
      PaymentProcessingNotifier,
      PaymentProcessingState
    >(PaymentProcessingNotifier.new);
