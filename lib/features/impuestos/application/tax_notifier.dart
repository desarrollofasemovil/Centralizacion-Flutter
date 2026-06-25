import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/api_providers.dart';
import '../data/tax_repository.dart';
import '../domain/tax.dart';

final taxRepositoryProvider = Provider<TaxRepository>((ref) {
  return TaxRepository(
    ref.watch(taxApiServiceProvider),
    ref.watch(paymentApiServiceProvider),
    ref.watch(fintechPaymentsApiServiceProvider),
  );
});

class TaxNotifier extends Notifier<AsyncValue<List<Tax>>> {
  @override
  AsyncValue<List<Tax>> build() {
    return const AsyncValue.data([]);
  }

  TaxRepository get _repository => ref.read(taxRepositoryProvider);

  Future<void> getTaxes({
    required String entityCode,
    required String queryData,
    required String queryField,
    required int taxId,
  }) async {
    state = const AsyncValue.loading();
    try {
      final list = await _repository.getTaxes(
        entityCode: entityCode,
        queryData: queryData,
        queryField: queryField,
        taxId: taxId,
      );
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

final taxNotifierProvider =
    NotifierProvider<TaxNotifier, AsyncValue<List<Tax>>>(TaxNotifier.new);
