import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/payment_history_api_service.dart';
import '../../../core/models/payment_history_dto.dart';
import '../../../core/review/review_prompt_service.dart';
import '../../auth/application/auth_providers.dart';

class HistoryPayNotifier extends Notifier<AsyncValue<PaymentHistoryListDTO>> {
  /// Última lista recibida. `fetchHistory` pone el estado en `loading` sin
  /// valor previo, así que el estado no sirve para saber cómo estaba un pago
  /// antes de sincronizarlo.
  PaymentHistoryListDTO _lastLoaded = const [];

  @override
  AsyncValue<PaymentHistoryListDTO> build() {
    _fetchHistoryInitial();
    return const AsyncValue.loading();
  }

  PaymentHistoryApiService get _apiService =>
      ref.read(paymentHistoryApiServiceProvider);
  int? get _userId => ref.watch(sessionProvider)?.id;

  void _fetchHistoryInitial() {
    Future.microtask(() => fetchHistory());
  }

  Future<void> fetchHistory() async {
    final userId = _userId;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final list = await _apiService.getHistoryPaymentByUser(userId);
      _lastLoaded = list;
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteHistory(int idHistory) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _apiService.deleteHistoryByUser(userId, idHistory);
      // Update local state by removing/filtering out the deleted item
      state.whenData((list) {
        final updated = list.where((item) => item.id != idHistory).toList();
        state = AsyncValue.data(updated);
      });
    } catch (e) {
      // Re-throw so UI can catch and show SnackBar
      rethrow;
    }
  }

  Future<void> syncPayment(int idHistory) async {
    final wasApproved = _statusOf(idHistory) == kPaymentStatusApproved;
    try {
      await _apiService.syncPaymentStatus(idHistory);
      // Reload history to get updated status from API
      await fetchHistory();
      // Reseña de la tienda cuando el pago pasa a aprobado (FSM-59).
      if (!wasApproved && _statusOf(idHistory) == kPaymentStatusApproved) {
        unawaited(
          ref
              .read(reviewPromptServiceProvider)
              .onPositiveMoment(ReviewTrigger.paymentApproved),
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  int? _statusOf(int idHistory) =>
      _lastLoaded.where((item) => item.id == idHistory).firstOrNull?.idStatusType;
}

final historyPayNotifierProvider =
    NotifierProvider<HistoryPayNotifier, AsyncValue<PaymentHistoryListDTO>>(
      HistoryPayNotifier.new,
    );
