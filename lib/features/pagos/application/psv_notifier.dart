import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/services/api_providers.dart';
import '../../auth/application/auth_providers.dart';
import '../../impuestos/application/tax_notifier.dart';
import '../../impuestos/data/tax_repository.dart';
import '../../impuestos/domain/tax.dart';
import '../../impuestos/domain/payment_gateway_info.dart';
import '../domain/psv_state.dart';

class PsvFormNotifier extends Notifier<PsvFormState> {
  @override
  PsvFormState build() {
    return const PsvFormState();
  }

  TaxRepository get _taxRepository => ref.read(taxRepositoryProvider);

  void updateField(PsvFormState Function(PsvFormState) updater) {
    state = updater(state);
  }

  void reset() {
    state = const PsvFormState();
  }

  /// Registro previo del pago en el historial (status `false`, statusType `2`),
  /// puerto fiel de `createHistoryPay` de `PsvPaymentViewModel.kt`. Es
  /// best-effort: si falla, el flujo de pago continúa igual que en el original.
  Future<void> createHistoryPay({
    required int amount,
    required String idImpuesto,
    required String factura,
    required String codigoEntidad,
    required int municipalityProceduresId,
  }) async {
    try {
      final user = ref.read(sessionProvider);
      final now = DateTime.now();
      final formattedDate =
          '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final body = <String, dynamic>{
        'userId': user?.id,
        'amount': amount,
        'paymentDate': formattedDate,
        'status': false,
        'municipalityProceduresId': municipalityProceduresId,
        'statusType': 2,
        'codigoEntidad': codigoEntidad,
        'factura': factura,
        'idimpuesto': idImpuesto,
      };
      await ref
          .read(paymentHistoryApiServiceProvider)
          .createPaymentHistory(body);
    } catch (_) {
      // Igual que el try/catch del original: la creación del historial no debe
      // bloquear el pago.
    }
  }

  Future<PaymentGatewayInfo> submitPsv({
    required int municipalityId,
    required String entityCode,
    required int taxId,
    required String taxName,
    required String integrationType,
  }) async {
    // Construct a mock Tax object to be used by the repository
    final tax = Tax(
      entity: 'Pago Sin Validación',
      entityCode: entityCode,
      document: state.documentNumber,
      name: state.fullName,
      taxName: taxName,
      taxId: taxId,
      value: state.amount,
      invoice: state.invoiceNumber.isNotEmpty
          ? state.invoiceNumber
          : 'PSV-${DateTime.now().millisecondsSinceEpoch}',
      reference: state.invoiceNumber.isNotEmpty
          ? state.invoiceNumber
          : 'PSV-${DateTime.now().millisecondsSinceEpoch}',
      dueDate: DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      queryField: 'Manual',
    );

    return await _taxRepository.createTransaction(
      tax: tax,
      email: state.email,
      bankName: state.selectedBank,
      municipalityId: municipalityId,
      integrationType: integrationType,
    );
  }
}

final psvFormNotifierProvider =
    NotifierProvider.autoDispose<PsvFormNotifier, PsvFormState>(
      PsvFormNotifier.new,
    );
