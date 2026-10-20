import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/services/api_providers.dart';
import 'package:tramiapp_flutter/core/api/services/payment_history_api_service.dart';
import 'package:tramiapp_flutter/core/models/validation_response_dto.dart';
import 'package:tramiapp_flutter/core/telemetry/non_fatal_reporter.dart';
import 'package:tramiapp_flutter/features/auth/application/auth_providers.dart';
import 'package:tramiapp_flutter/features/impuestos/application/tax_notifier.dart';
import 'package:tramiapp_flutter/features/impuestos/application/tax_results_notifier.dart';
import 'package:tramiapp_flutter/features/impuestos/data/tax_repository.dart';
import 'package:tramiapp_flutter/features/impuestos/domain/payment_gateway_info.dart';
import 'package:tramiapp_flutter/features/impuestos/domain/tax.dart';
import 'package:tramiapp_flutter/core/models/user_dto.dart';

const _tax = Tax(
  entity: 'Alcaldía',
  entityCode: '05030',
  document: '123',
  name: 'Ana',
  taxName: 'Predial',
  taxId: 1,
  value: 25000,
  invoice: 'FAC-1',
  reference: 'REF',
  dueDate: '',
  queryField: '',
);

/// Orden real de las llamadas.
final _calls = <String>[];

class _HistoryApi implements PaymentHistoryApiService {
  _HistoryApi({this.fail = false});

  final bool fail;
  Map<String, dynamic>? lastBody;

  @override
  Future<ValidationResponseDTO> createPaymentHistory(
    Map<String, dynamic> body,
  ) async {
    lastBody = body;
    // Deja pasar un ciclo: si el flujo no esperara, la transacción se colaría.
    await Future<void>.delayed(Duration.zero);
    _calls.add('registro');
    if (fail) throw StateError('POST api/PaymentHistory falló');
    return ValidationResponseDTO(codeStatus: 200, booleanStatus: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Repo implements TaxRepository {
  @override
  Future<PaymentGatewayInfo> createTransaction({
    required Tax tax,
    required String email,
    required String bankName,
    required int municipalityId,
    required String integrationType,
    String phone = '',
  }) async {
    _calls.add('transaccion');
    return const PaymentGatewayInfo(url: 'https://pasarela.test/pago');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _SpyReporter implements NonFatalReporter {
  final reports = <({String reason, Map<String, Object?> context})>[];

  @override
  void report(
    String reason, {
    Map<String, Object?> context = const {},
    Object? error,
    StackTrace? stackTrace,
  }) => reports.add((reason: reason, context: context));
}

class _NoSession extends SessionNotifier {
  @override
  UserDTO? build() => null;
}

({ProviderContainer container, _SpyReporter reporter}) _setUp(_HistoryApi api) {
  _calls.clear();
  final reporter = _SpyReporter();
  final container = ProviderContainer(
    overrides: [
      sessionProvider.overrideWith(_NoSession.new),
      paymentHistoryApiServiceProvider.overrideWithValue(api),
      taxRepositoryProvider.overrideWithValue(_Repo()),
      nonFatalReporterProvider.overrideWithValue(reporter),
    ],
  );
  addTearDown(container.dispose);
  return (container: container, reporter: reporter);
}

Future<void> _pay(ProviderContainer container, {int? procedureId = 3}) =>
    container
        .read(taxResultsNotifierProvider.notifier)
        .payTax(
          tax: _tax,
          email: 'x@y.co',
          bankName: 'Bancolombia',
          municipalityId: 14,
          integrationType: 'psv',
          municipalityProceduresId: procedureId,
        );

void main() {
  test('el registro en el historial termina ANTES de pedir la transacción', () async {
    final api = _HistoryApi();
    final (:container, :reporter) = _setUp(api);
    container.listen(taxResultsNotifierProvider, (_, _) {});

    await _pay(container);

    expect(_calls, ['registro', 'transaccion']);
    expect(api.lastBody!['municipalityProceduresId'], 3);
    expect(api.lastBody!['statusType'], 2);
    expect(reporter.reports, isEmpty);
    expect(
      container.read(taxResultsNotifierProvider).paymentUrl,
      'https://pasarela.test/pago',
    );
  });

  test('si el registro falla, igual se paga y queda el no fatal sin datos personales',
      () async {
    final (:container, :reporter) = _setUp(_HistoryApi(fail: true));
    container.listen(taxResultsNotifierProvider, (_, _) {});

    await _pay(container);

    expect(_calls, ['registro', 'transaccion']);
    expect(container.read(taxResultsNotifierProvider).paymentUrl, isNotNull);
    final report = reporter.reports.single;
    expect(report.reason, contains('historial'));
    expect(report.context['municipalityProceduresId'], 3);
    expect(report.context['idimpuesto'], '1');
    // Nada del ciudadano en el rastro.
    final traced = report.context.values.map((v) => '$v').join(' ');
    for (final personal in ['x@y.co', 'Ana', '123', 'FAC-1']) {
      expect(traced, isNot(contains(personal)));
    }
  });

  test('sin trámite del municipio se paga sin registro, pero con rastro', () async {
    final (:container, :reporter) = _setUp(_HistoryApi());
    container.listen(taxResultsNotifierProvider, (_, _) {});

    await _pay(container, procedureId: null);

    expect(_calls, ['transaccion']);
    expect(reporter.reports.single.reason, contains('faltan datos'));
  });

  test('mientras corre, un segundo toque no lanza otro pago', () async {
    final (:container, reporter: _) = _setUp(_HistoryApi());
    container.listen(taxResultsNotifierProvider, (_, _) {});

    await Future.wait([_pay(container), _pay(container)]);

    expect(_calls, ['registro', 'transaccion']);
  });
}
