import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/payment_history_api_service.dart';
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
          final latest = history.reduce((a, b) => a.id > b.id ? a : b);
          await api.syncPaymentStatus(latest.id);
          // Reseña de la tienda si el pago pasó a aprobado con esta
          // verificación (FSM-59). Si ya lo estaba, no se relee. Sin `await`:
          // la navegación al Historial no espera esa lectura extra.
          if (latest.idStatusType != kPaymentStatusApproved) {
            unawaited(
              _reviewIfApproved(
                api,
                ref.read(reviewPromptServiceProvider),
                userId,
                latest.id,
              ),
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

  /// Corre después de que la pantalla navegó (el notifier autoDispose ya
  /// puede estar liberado): por eso recibe el servicio y la API, no `ref`.
  static Future<void> _reviewIfApproved(
    PaymentHistoryApiService api,
    ReviewPromptService review,
    int userId,
    int idHistory,
  ) async {
    try {
      final synced = await api.getHistoryPaymentByUser(userId);
      final status =
          synced.where((h) => h.id == idHistory).firstOrNull?.idStatusType;
      if (status == kPaymentStatusApproved) {
        await review.onPositiveMoment(ReviewTrigger.paymentApproved);
      }
    } catch (_) {
      // Best-effort: sin red, simplemente no se pide la reseña.
    }
  }
}

final paymentProcessingNotifierProvider =
    NotifierProvider.autoDispose<
      PaymentProcessingNotifier,
      PaymentProcessingState
    >(PaymentProcessingNotifier.new);
