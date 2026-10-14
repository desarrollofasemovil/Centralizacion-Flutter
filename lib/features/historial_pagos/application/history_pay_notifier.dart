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

  /// Usuario de la sesión, fijado en [build]. Solo se observa el id: un cambio
  /// de usuario (cerrar sesión y entrar con otro) reconstruye el notifier y
  /// vuelve a pedir la lista; otros cambios de la sesión no.
  int? _userId;

  @override
  AsyncValue<PaymentHistoryListDTO> build() {
    _userId = ref.watch(sessionProvider.select((user) => user?.id));
    // Mantiene vivo el set de "sincronizando" mientras viva el historial.
    ref.listen(historySyncingIdsProvider, (_, _) {});
    Future.microtask(fetchHistory);
    return const AsyncValue.loading();
  }

  PaymentHistoryApiService get _apiService =>
      ref.read(paymentHistoryApiServiceProvider);

  /// Carga la lista. Con [silent] y una lista ya en pantalla, no pasa por
  /// `loading`: la lista visible se queda hasta que llega la nueva (y se queda
  /// si la recarga falla). Así refrescar no reemplaza toda la pantalla por los
  /// placeholders de carga.
  Future<void> fetchHistory({bool silent = false}) async {
    // `autoDispose`: la pantalla puede cerrarse antes de que llegue la
    // respuesta; entonces ya no hay a quién escribirle el estado.
    if (!ref.mounted) return;
    final userId = _userId;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }
    final keepVisible = silent && state.hasValue;
    if (!keepVisible) state = const AsyncValue.loading();
    try {
      final list = paymentHistoryFromResponse(
        await _apiService.getHistoryPaymentByUser(userId),
      );
      if (!ref.mounted) return;
      _lastLoaded = list;
      state = AsyncValue.data(list);
    } catch (e, stack) {
      if (!ref.mounted || keepVisible) return;
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteHistory(int idHistory) async {
    final userId = _userId;
    if (userId == null) return;
    try {
      await _apiService.deleteHistoryByUser(userId, idHistory);
      if (!ref.mounted) return;
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

  /// Sincroniza un pago y recarga la lista en silencio. Si falla, relanza.
  Future<void> syncPayment(int idHistory) =>
      _syncAndReload([idHistory], rethrowErrors: true);

  /// Deslizar para refrescar: sincroniza con la pasarela todos los pagos en
  /// curso (COMENZADA, como el original) y recarga la lista **una sola vez** al
  /// final. Mientras tanto esas tarjetas muestran el estado cargando
  /// ([historySyncingIdsProvider]). Un pago que no se pueda sincronizar no
  /// detiene a los demás.
  Future<void> refreshPending() async {
    final pending = [
      for (final p in _lastLoaded)
        if (p.isInProgress) p.id,
    ];
    await _syncAndReload(pending);
  }

  Future<void> _syncAndReload(
    List<int> ids, {
    bool rethrowErrors = false,
  }) async {
    final wasApproved = {
      for (final id in ids) id: _statusOf(id) == kPaymentStatusApproved,
    };
    final syncing = ref.read(historySyncingIdsProvider.notifier)..add(ids);
    try {
      for (final id in ids) {
        try {
          await _apiService.syncPaymentStatus(id);
        } catch (_) {
          if (rethrowErrors) rethrow;
        }
      }
      await fetchHistory(silent: true);
      if (!ref.mounted) return;
      // Reseña de la tienda cuando un pago pasa a aprobado (FSM-59). Una sola
      // vez aunque se aprueben varios en el mismo refresco.
      final approvedNow = ids.any(
        (id) => !wasApproved[id]! && _statusOf(id) == kPaymentStatusApproved,
      );
      if (approvedNow) {
        unawaited(
          ref
              .read(reviewPromptServiceProvider)
              .onPositiveMoment(ReviewTrigger.paymentApproved),
        );
      }
    } finally {
      if (ref.mounted) syncing.remove(ids);
    }
  }

  int? _statusOf(int idHistory) =>
      _lastLoaded.where((item) => item.id == idHistory).firstOrNull?.idStatusType;
}

/// `autoDispose`: cada entrada al Historial pide la lista de nuevo. Sin esto la
/// primera lista de la sesión quedaba fija para toda la vida de la app, y el
/// pago recién hecho (Pagar → "Verificar estado" → Historial) solo aparecía
/// tras deslizar para refrescar. Solo lo lee `HistoryPayScreen`.
final historyPayNotifierProvider =
    NotifierProvider.autoDispose<
      HistoryPayNotifier,
      AsyncValue<PaymentHistoryListDTO>
    >(HistoryPayNotifier.new);

/// Ids de los pagos que se están sincronizando ahora mismo: sus tarjetas
/// muestran el estado cargando en vez de toda la pantalla.
class HistorySyncingIds extends Notifier<Set<int>> {
  @override
  Set<int> build() => const {};

  void add(Iterable<int> ids) => state = {...state, ...ids};

  void remove(Iterable<int> ids) => state = state.difference(ids.toSet());
}

final historySyncingIdsProvider =
    NotifierProvider.autoDispose<HistorySyncingIds, Set<int>>(
      HistorySyncingIds.new,
    );
