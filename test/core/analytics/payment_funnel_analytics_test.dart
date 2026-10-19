import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/analytics/analytics_service.dart';
import 'package:tramiapp_flutter/core/models/payment_history_dto.dart';

import '../../support/recording_analytics.dart';

PaymentHistoryDTO _payment({
  int id = 7,
  int status = 1,
  double amount = 25000,
}) => PaymentHistoryDTO(
  id: id,
  userFirtName: 'Ana',
  amount: amount,
  paymentDate: '2026-10-19',
  status: status == 1,
  idStatusType: status,
  alcaldia: 'Alcaldía',
  procedureName: 'Predial',
  statusType: '',
  idimpuesto: '12',
  factura: 'F-1',
  codigoEntidad: '05030',
);

DioException _dio(DioExceptionType type, {int? status}) => DioException(
  requestOptions: RequestOptions(path: '/api/Tax?documento=123456'),
  type: type,
  response: status == null
      ? null
      : Response(
          requestOptions: RequestOptions(path: '/api/Tax'),
          statusCode: status,
        ),
);

void main() {
  late RecordingAnalytics analytics;
  setUp(() => analytics = RecordingAnalytics());

  group('consulta de impuesto', () {
    test('enviada: tipo de consulta, nunca el documento', () async {
      await analytics.logTaxQuerySent(
        municipalityId: 3,
        taxId: 12,
        entityCode: '05030',
        queryField: 'Documento',
      );
      expect(analytics.single('consulta_impuesto_enviada'), {
        'municipio_id': 3,
        'impuesto_id': 12,
        'entidad_codigo': '05030',
        'tipo_consulta': 'Documento',
      });
    });

    test('encontrado: cantidad y valor total', () async {
      await analytics.logTaxQueryResult(
        municipalityId: 3,
        taxId: 12,
        outcome: TaxQueryOutcome.found,
        count: 2,
        totalValue: 50000,
      );
      expect(analytics.single('consulta_impuesto_resultado'), {
        'municipio_id': 3,
        'impuesto_id': 12,
        'resultado': 'encontrado',
        'cantidad': 2,
        'valor_total': 50000,
      });
    });

    test('sin deuda: sin cantidad ni motivo', () async {
      await analytics.logTaxQueryResult(
        municipalityId: 3,
        taxId: 12,
        outcome: TaxQueryOutcome.noDebt,
      );
      expect(analytics.single('consulta_impuesto_resultado'), {
        'municipio_id': 3,
        'impuesto_id': 12,
        'resultado': 'sin_deuda',
      });
    });

    test('error: motivo corto, sin la URL (que trae el documento)', () async {
      await analytics.logTaxQueryResult(
        municipalityId: 3,
        taxId: 12,
        outcome: TaxQueryOutcome.error,
        error: _dio(DioExceptionType.badResponse, status: 500),
      );
      final params = analytics.single('consulta_impuesto_resultado')!;
      expect(params['resultado'], 'error');
      expect(params['motivo'], 'http_500');
      expect(params.values.join(), isNot(contains('123456')));
    });
  });

  test('pasarela abierta: solo el dominio de la URL', () async {
    await analytics.logGatewayOpened(
      municipalityId: 3,
      origin: PaymentOrigin.psv,
      paymentUrl: 'https://checkout.pasarela.co/pay?token=abc&doc=123',
      taxId: 12,
    );
    expect(analytics.single('pasarela_abierta'), {
      'municipio_id': 3,
      'origen': 'psv',
      'url_dominio': 'checkout.pasarela.co',
      'impuesto_id': 12,
    });
  });

  group('pago verificado', () {
    test('estados del historial → aprobado / pendiente / rechazado', () {
      expect(AnalyticsService.paymentResult(1), 'aprobado');
      expect(AnalyticsService.paymentResult(2), 'pendiente');
      expect(AnalyticsService.paymentResult(3), 'rechazado');
      expect(AnalyticsService.paymentResult(4), 'rechazado');
      expect(AnalyticsService.paymentResult(0), 'desconocido');
    });

    test('lleva estado, pantalla, origen y valor', () async {
      await analytics.logPaymentVerified(
        municipalityId: 3,
        payment: _payment(status: 2),
        screen: VerificationScreen.processing,
        origin: PaymentOrigin.taxQuery,
      );
      expect(analytics.single('pago_verificado'), {
        'municipio_id': 3,
        'origen': 'consulta_impuesto',
        'resultado': 'pendiente',
        'estado_id': 2,
        'pantalla': 'procesamiento',
        'valor': 25000.0,
      });
    });

    test('desde el historial no hay origen', () async {
      await analytics.logPaymentVerified(
        municipalityId: 3,
        payment: _payment(status: 3),
        screen: VerificationScreen.history,
      );
      final params = analytics.single('pago_verificado')!;
      expect(params.containsKey('origen'), isFalse);
      expect(params['pantalla'], 'historial');
      expect(params['resultado'], 'rechazado');
    });
  });

  group('purchase', () {
    test('aprobado: value en COP y transaction_id del historial', () async {
      await analytics.logPaymentApproved(
        municipalityId: 3,
        payment: _payment(id: 41, amount: 125000),
      );
      expect(analytics.single('purchase'), {
        'currency': 'COP',
        'value': 125000.0,
        'transaction_id': 'hist_41',
        'municipio_id': 3,
        'impuesto_id': '12',
      });
    });

    test('nunca para un pago que el backend no confirma aprobado', () async {
      for (final status in [0, 2, 3, 4]) {
        await analytics.logPaymentApproved(
          municipalityId: 3,
          payment: _payment(status: status),
        );
      }
      expect(analytics.events, isEmpty);
    });
  });

  group('pago_error', () {
    test('con motivo explícito', () async {
      await analytics.logPaymentError(
        municipalityId: 3,
        origin: PaymentOrigin.certificate,
        stage: PaymentStage.noUrl,
        reason: 'url_vacia',
      );
      expect(analytics.single('pago_error'), {
        'municipio_id': 3,
        'origen': 'certificado',
        'etapa': 'sin_url',
        'motivo': 'url_vacia',
      });
    });

    test('motivo derivado del error', () async {
      await analytics.logPaymentError(
        municipalityId: 3,
        origin: PaymentOrigin.taxQuery,
        stage: PaymentStage.transaction,
        error: _dio(DioExceptionType.connectionError),
      );
      expect(analytics.single('pago_error')!['motivo'], 'sin_conexion');
      expect(analytics.single('pago_error')!['etapa'], 'transaccion');
    });
  });

  test('errorReason reduce cualquier error a un código corto', () {
    expect(
      AnalyticsService.errorReason(_dio(DioExceptionType.receiveTimeout)),
      'timeout',
    );
    expect(
      AnalyticsService.errorReason(
        _dio(DioExceptionType.badResponse, status: 404),
      ),
      'http_404',
    );
    expect(AnalyticsService.errorReason(_dio(DioExceptionType.unknown)), 'red');
    expect(AnalyticsService.errorReason(StateError('x')), 'StateError');
    expect(AnalyticsService.errorReason(null), 'desconocido');
  });
}
