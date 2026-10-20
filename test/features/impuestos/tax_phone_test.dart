import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/services/fintech_api_service.dart';
import 'package:tramiapp_flutter/core/api/services/tax_api_service.dart';
import 'package:tramiapp_flutter/core/models/query_field.dart';
import 'package:tramiapp_flutter/core/models/tax_dto.dart';
import 'package:tramiapp_flutter/features/impuestos/application/tax_notifier.dart';
import 'package:tramiapp_flutter/features/impuestos/data/tax_repository.dart';
import 'package:tramiapp_flutter/features/impuestos/domain/tax.dart';

const _tax = Tax(
  entity: 'Alcaldía',
  entityCode: '05030',
  document: '123',
  name: 'Ana Pérez',
  taxName: 'Predial',
  taxId: 1,
  value: 25000,
  invoice: 'FAC-1',
  reference: 'REF',
  dueDate: '',
  queryField: '',
);

class _PaymentApi implements PaymentApiService {
  BancolombiaGatewayRequestDTO? sent;

  @override
  Future<BancolombiaGatewayResponseDTO> createTransaction(
    BancolombiaGatewayRequestDTO body,
  ) async {
    sent = body;
    return const BancolombiaGatewayResponseDTO(url: 'https://pasarela.test');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FintechApi implements FintechPaymentsApiService {
  FintechTransactionRequestDTO? sent;

  @override
  Future<FintechTransactionResponseDTO> transactionFintech(
    int id,
    FintechTransactionRequestDTO body,
  ) async {
    sent = body;
    return const FintechTransactionResponseDTO(
      isSuccess: true,
      result: FintechResultDTO(url: 'https://fintech.test'),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

TaxQueryState _validState({String phone = ''}) => TaxQueryState(
  selectedQueryField: QueryField(
    id: 1,
    queryFieldType: 'Cédula',
    fieldName: 'documento',
  ),
  documentNumber: '123',
  email: 'ana@correo.co',
  phone: phone,
  acceptsPolicies: true,
  acceptsConditions: true,
);

void main() {
  group('teléfono opcional del formulario', () {
    test('vacío no bloquea la consulta', () {
      expect(_validState().isQueryButtonEnabled, isTrue);
    });

    test('con 10 dígitos pasa', () {
      expect(_validState(phone: '3001234567').isQueryButtonEnabled, isTrue);
    });

    test('incompleto sí la bloquea', () {
      final state = _validState(phone: '30012');
      expect(state.isPhoneValid, isFalse);
      expect(state.isQueryButtonEnabled, isFalse);
    });
  });

  group('el teléfono llega a la pasarela', () {
    test('Bancolombia lo envía como Telefono', () async {
      final payment = _PaymentApi();
      final repo = TaxRepository(_NoTaxApi(), payment, _FintechApi());

      await repo.createTransaction(
        tax: _tax,
        email: 'ana@correo.co',
        bankName: 'Bancolombia',
        municipalityId: 14,
        integrationType: '0',
        phone: '3001234567',
      );

      expect(payment.sent!.phone, '3001234567');
      expect(payment.sent!.toJson()['Telefono'], '3001234567');
    });

    test('Coopcentral lo envía en el pagador', () async {
      final fintech = _FintechApi();
      final repo = TaxRepository(_NoTaxApi(), _PaymentApi(), fintech);

      await repo.createTransaction(
        tax: _tax,
        email: 'ana@correo.co',
        bankName: 'Coopcentral',
        municipalityId: 14,
        integrationType: '7',
        phone: '3001234567',
      );

      expect(fintech.sent!.pagador!.telefono, '3001234567');
    });

    test('sin teléfono se envía vacío, como antes', () async {
      final payment = _PaymentApi();
      final repo = TaxRepository(_NoTaxApi(), payment, _FintechApi());

      await repo.createTransaction(
        tax: _tax,
        email: 'ana@correo.co',
        bankName: 'Bancolombia',
        municipalityId: 14,
        integrationType: '0',
      );

      expect(payment.sent!.phone, '');
    });
  });
}

class _NoTaxApi implements TaxApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
