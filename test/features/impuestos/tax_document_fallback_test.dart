import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/api/services/fintech_api_service.dart';
import 'package:tramiapp_flutter/core/api/services/tax_api_service.dart';
import 'package:tramiapp_flutter/core/models/tax_dto.dart';
import 'package:tramiapp_flutter/features/impuestos/data/tax_repository.dart';

/// La consulta de apidatamovil puede traer la factura con `Documento` vacío
/// (visto en el servidor de pruebas, Inírida). La pasarela de Bancolombia no
/// carga ningún dato del pagador si falta uno, así que el documento se toma del
/// número que el ciudadano consultó.
class _TaxApi implements TaxApiService {
  _TaxApi(this.document);

  final String? document;

  @override
  Future<TaxQueryResponseDTO> getTaxes(TaxQueryRequestDTO body) async {
    return TaxQueryResponseDTO(
      information: [
        TaxInfoDTO(
          entityCode: '8920991057',
          document: document,
          name: 'TERESA SCARPETTA AMAYA',
          taxName: 'Impuesto Predial Unificado',
          taxId: 1,
          value: 7899874,
          reference: '117232',
          dueDate: '31/10/2026',
          facturaCode: '00117232',
        ),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

Future<String> _documentOf(String? fromApi) async {
  final repo = TaxRepository(_TaxApi(fromApi), _PaymentApi(), _FintechApi());
  final taxes = await repo.getTaxes(
    entityCode: '8920991057',
    queryData: '41234567',
    queryField: 'documento',
    taxId: 1,
  );
  return taxes.single.document;
}

void main() {
  group('documento de la factura', () {
    test('vacío: se usa el número consultado', () async {
      expect(await _documentOf(''), '41234567');
    });

    test('solo espacios o null: se usa el número consultado', () async {
      expect(await _documentOf('  '), '41234567');
      expect(await _documentOf(null), '41234567');
    });

    test('si la factura lo trae, manda el de la factura', () async {
      expect(await _documentOf('98765432'), '98765432');
    });
  });

  group('la pasarela recibe el documento', () {
    test('Bancolombia: Identificacion lleno y TipoDocumento CC', () async {
      final payment = _PaymentApi();
      final repo = TaxRepository(_TaxApi(''), payment, _FintechApi());
      final tax = (await repo.getTaxes(
        entityCode: '8920991057',
        queryData: '41234567',
        queryField: 'documento',
        taxId: 1,
      )).single;

      await repo.createTransaction(
        tax: tax,
        email: 'ana@correo.co',
        bankName: 'Bancolombia',
        municipalityId: 81,
        integrationType: '0',
      );

      expect(payment.sent!.toJson()['Identificacion'], '41234567');
      expect(payment.sent!.toJson()['TipoDocumento'], 'CC');
    });

    test('Coopcentral: documento del pagador lleno', () async {
      final fintech = _FintechApi();
      final repo = TaxRepository(_TaxApi(''), _PaymentApi(), fintech);
      final tax = (await repo.getTaxes(
        entityCode: '8920991057',
        queryData: '41234567',
        queryField: 'documento',
        taxId: 1,
      )).single;

      await repo.createTransaction(
        tax: tax,
        email: 'ana@correo.co',
        bankName: 'Coopcentral',
        municipalityId: 81,
        integrationType: '7',
      );

      expect(fintech.sent!.pagador!.documento, '41234567');
    });
  });
}
