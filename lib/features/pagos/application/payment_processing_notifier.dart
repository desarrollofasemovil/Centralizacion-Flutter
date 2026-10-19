import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_service.dart';
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
  ///
  /// [municipalityId] y [origin] solo alimentan la analítica del embudo
  /// (`pago_verificado`, `purchase`, `pago_error`).
  Future<bool> onCheckStatusClick({
    required int municipalityId,
    required PaymentOrigin origin,
  }) async {
    if (!state.isCheckEnabled) return false;
    state = state.copyWith(isVerifying: true);
    final analytics = ref.read(analyticsServiceProvider);
    void logError({Object? error, String? reason}) => unawaited(
      analytics.logPaymentError(
        municipalityId: municipalityId,
        origin: origin,
        stage: PaymentStage.verification,
        error: error,
        reason: reason,
      ),
    );
    try {
      final userId = ref.read(sessionProvider)?.id;
      if (userId != null) {
        final api = ref.read(paymentHistoryApiServiceProvider);
        final history = paymentHistoryFromResponse(
          await api.getHistoryPaymentByUser(userId),
        );
        if (history.isNotEmpty) {
          final latest = history.reduce((a, b) => a.id > b.id ? a : b);
          await api.syncPaymentStatus(latest.id);
          // Estado tras sincronizar: analítica y reseña de la tienda (FSM-59).
          // Sin `await`: la navegación al Historial no espera esa lectura.
          unawaited(
            _afterSync(
              api,
              ref.read(reviewPromptServiceProvider),
              analytics,
              userId: userId,
              before: latest,
              municipalityId: municipalityId,
              origin: origin,
            ),
          );
        } else {
          // Se abrió la pasarela pero el pago no quedó en el historial.
          logError(reason: 'historial_vacio');
        }
      }
    } catch (e) {
      // Igual que el runCatching del original: la verificación es best-effort;
      // el Historial mostrará el estado que tenga el backend.
      logError(error: e);
    }
    state = state.copyWith(isVerifying: false);
    return true;
  }

  /// Corre después de que la pantalla navegó (el notifier autoDispose ya
  /// puede estar liberado): por eso recibe los servicios, no `ref`.
  ///
  /// Relee el pago sincronizado y registra `pago_verificado`. Si pasó a
  /// aprobado con **esta** verificación, también `purchase` y la reseña; si ya
  /// estaba aprobado (pago viejo, o el registro del nuevo falló) no se cuenta
  /// como compra.
  static Future<void> _afterSync(
    PaymentHistoryApiService api,
    ReviewPromptService review,
    AnalyticsService analytics, {
    required int userId,
    required PaymentHistoryDTO before,
    required int municipalityId,
    required PaymentOrigin origin,
  }) async {
    try {
      final synced = paymentHistoryFromResponse(
        await api.getHistoryPaymentByUser(userId),
      ).where((h) => h.id == before.id).firstOrNull;
      if (synced == null) return;
      await analytics.logPaymentVerified(
        municipalityId: municipalityId,
        payment: synced,
        screen: VerificationScreen.processing,
        origin: origin,
      );
      if (synced.idStatusType == kPaymentStatusApproved &&
          before.idStatusType != kPaymentStatusApproved) {
        await analytics.logPaymentApproved(
          municipalityId: municipalityId,
          payment: synced,
        );
        await review.onPositiveMoment(ReviewTrigger.paymentApproved);
      }
    } catch (_) {
      // Best-effort: sin red, simplemente no se mide ni se pide la reseña.
    }
  }
}

final paymentProcessingNotifierProvider =
    NotifierProvider.autoDispose<
      PaymentProcessingNotifier,
      PaymentProcessingState
    >(PaymentProcessingNotifier.new);
