import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/municipality_procedure.dart';
import 'package:tramiapp_flutter/core/models/procedures.dart';
import 'package:tramiapp_flutter/features/tramites/domain/procedure_identity.dart';

MunicipalityProcedure _mp(int rowId, Map<String, dynamic> procedure) =>
    MunicipalityProcedure.fromJson({
      'id': rowId,
      'integrationType': '',
      'isActive': true,
      'procedures': procedure,
    });

void main() {
  group('Procedures.fromJson', () {
    test('lee code, kind, externalId y gatewayTaxId', () {
      final p = Procedures.fromJson({
        'id': 9,
        'name': 'Contribución al Turismo',
        'code': 'CERT_TURISMO',
        'kind': 'CERTIFICATE',
        'externalId': 13,
        'gatewayTaxId': 269,
      });
      expect(p.code, 'CERT_TURISMO');
      expect(p.kind, 'CERTIFICATE');
      expect(p.externalId, 13);
      expect(p.gatewayTaxId, 269);
    });

    test('sin los campos (API sin identidad) quedan en null', () {
      final p = Procedures.fromJson({'id': 1, 'name': 'Predial'});
      expect(p.code, isNull);
      expect(p.kind, isNull);
      expect(p.externalId, isNull);
      expect(p.gatewayTaxId, isNull);
    });

    test('tipos inesperados no rompen la lectura', () {
      final p = Procedures.fromJson({
        'id': 1,
        'name': 'Predial',
        'code': 7,
        'kind': '  ',
        'externalId': '13',
        'gatewayTaxId': true,
      });
      expect(p.code, isNull);
      expect(p.kind, isNull);
      expect(p.externalId, 13);
      expect(p.gatewayTaxId, isNull);
    });
  });

  group('ProcedureKind.tryParse', () {
    test('valores del API', () {
      expect(ProcedureKind.tryParse('TAX'), ProcedureKind.tax);
      expect(
        ProcedureKind.tryParse('PUBLIC_SERVICES'),
        ProcedureKind.publicServices,
      );
      expect(ProcedureKind.tryParse('PANIC_BUTTON'), ProcedureKind.panicButton);
      expect(ProcedureKind.tryParse('other'), ProcedureKind.other);
    });

    test('desconocido o ausente → null', () {
      expect(ProcedureKind.tryParse('EXTERNAL_LINK'), isNull);
      expect(ProcedureKind.tryParse(null), isNull);
    });
  });

  group('resolveProcedure con identidad', () {
    test('la identidad del API gana sobre el id', () {
      // En desarrollo el 9 es el certificado de turismo, no Reservas.
      final identity = resolveProcedure(
        Procedures(
          id: 9,
          name: 'Contribución al Turismo',
          code: 'CERT_TURISMO',
          kind: 'CERTIFICATE',
          externalId: 13,
        ),
        responseHasIdentity: true,
      );
      expect(
        identity,
        const ProcedureIdentity(
          kind: ProcedureKind.certificate,
          code: 'CERT_TURISMO',
          externalId: 13,
          gatewayTaxId: 269,
        ),
      );
    });

    test('externalId tal como llega, sin caer al id', () {
      final identity = resolveProcedure(
        Procedures(id: 4, name: 'PQRDSF', code: 'PQRSDF', kind: 'PQRSDF'),
        responseHasIdentity: true,
      );
      expect(identity!.kind, ProcedureKind.pqrsdf);
      expect(identity.externalId, isNull);
    });

    test('respuesta mixta: el trámite sin kind se oculta', () {
      // En desarrollo el 8 es una fila de prueba, no Cursos.
      expect(
        resolveProcedure(
          Procedures(id: 8, name: 'Tramite de prueba'),
          responseHasIdentity: true,
        ),
        isNull,
      );
    });

    test('kind desconocido → oculto', () {
      expect(
        resolveProcedure(
          Procedures(id: 30, name: 'Nuevo', code: 'NUEVO', kind: 'FUTURE'),
          responseHasIdentity: true,
        ),
        isNull,
      );
    });

    test('code desconocido: conserva su kind, sin id de pasarela', () {
      final identity = resolveProcedure(
        Procedures(
          id: 13,
          name: 'Test',
          code: 'CERT_TEST',
          kind: 'CERTIFICATE',
          externalId: 14,
        ),
        responseHasIdentity: true,
      );
      expect(identity!.kind, ProcedureKind.certificate);
      expect(identity.code, 'CERT_TEST');
      expect(identity.gatewayTaxId, isNull);
    });

    test('gatewayTaxId servido gana sobre la constante por code', () {
      final identity = resolveProcedure(
        Procedures(
          id: 10,
          name: 'Certificado de Residencia',
          code: 'CERT_RESIDENCIA',
          kind: 'CERTIFICATE',
          externalId: 11,
          gatewayTaxId: 999,
        ),
        responseHasIdentity: true,
      );
      expect(identity!.gatewayTaxId, 999);
    });

    test('ids de pasarela por code mientras no se sirven', () {
      int? gateway(String code) => resolveProcedure(
        Procedures(id: 1, name: '', code: code, kind: 'CERTIFICATE'),
        responseHasIdentity: true,
      )!.gatewayTaxId;
      expect(gateway('CERT_RESIDENCIA'), 43);
      expect(gateway('CERT_PAZ_SALVO'), 26);
      expect(gateway('CERT_TURISMO'), 269);
      expect(gateway('CERT_USO_SUELO'), 20);
    });
  });

  group('resolveProcedure legacy (respuesta sin identidad)', () {
    test('tabla por id 1–14 con externalId = id', () {
      const expected = {
        1: ('PREDIAL', ProcedureKind.tax),
        2: ('ICA', ProcedureKind.tax),
        3: ('DECLARACION', ProcedureKind.tax),
        4: ('PQRSDF', ProcedureKind.pqrsdf),
        5: ('SERVICIOS_PUBLICOS', ProcedureKind.publicServices),
        6: ('VEHICULOS', ProcedureKind.tax),
        7: ('RETE_ICA', ProcedureKind.tax),
        8: ('CURSOS', ProcedureKind.courses),
        9: ('RESERVA_ESPACIOS', ProcedureKind.venues),
        10: ('BOTON_PANICO', ProcedureKind.panicButton),
        11: ('CERT_RESIDENCIA', ProcedureKind.certificate),
        12: ('CERT_PAZ_SALVO', ProcedureKind.certificate),
        13: ('CERT_TURISMO', ProcedureKind.certificate),
        14: ('CERT_USO_SUELO', ProcedureKind.certificate),
      };
      expected.forEach((id, value) {
        final identity = resolveProcedure(
          Procedures(id: id, name: ''),
          responseHasIdentity: false,
        );
        expect(identity!.code, value.$1, reason: 'id $id');
        expect(identity.kind, value.$2, reason: 'id $id');
        expect(identity.externalId, id, reason: 'id $id');
      });
    });

    test('certificados legacy con sus ids de pasarela', () {
      expect(
        resolveProcedure(
          Procedures(id: 13, name: ''),
          responseHasIdentity: false,
        )!.gatewayTaxId,
        269,
      );
    });

    test('id fuera de la tabla → oculto', () {
      expect(
        resolveProcedure(
          Procedures(id: 15, name: 'Otro'),
          responseHasIdentity: false,
        ),
        isNull,
      );
      expect(
        resolveProcedure(
          Procedures(id: 0, name: ''),
          responseHasIdentity: false,
        ),
        isNull,
      );
    });
  });

  group('responseHasProcedureIdentity', () {
    test('basta con un trámite con kind (aunque sea desconocido)', () {
      expect(
        responseHasProcedureIdentity([
          _mp(1, {'id': 1, 'name': 'Predial'}),
          _mp(2, {'id': 30, 'name': 'Nuevo', 'kind': 'FUTURE'}),
        ]),
        isTrue,
      );
    });

    test('ninguno con kind → legacy', () {
      expect(
        responseHasProcedureIdentity([
          _mp(1, {'id': 1, 'name': 'Predial'}),
        ]),
        isFalse,
      );
    });
  });

  group('findTaxProcedureByExternalId', () {
    test('cruza el Id_Impuesto con externalId aunque el id sea otro', () {
      final procedures = [
        _mp(500, {
          'id': 230,
          'name': 'Impuesto Predial Unificado',
          'code': 'PREDIAL',
          'kind': 'TAX',
          'externalId': 1,
        }),
        _mp(501, {
          'id': 1,
          'name': 'Certificado de Residencia',
          'code': 'CERT_RESIDENCIA',
          'kind': 'CERTIFICATE',
          'externalId': 11,
        }),
      ];
      expect(findTaxProcedureByExternalId(procedures, 1)!.id, 500);
      expect(findTaxProcedureByExternalId(procedures, 230), isNull);
      // Un certificado no es un impuesto aunque coincida el número.
      expect(findTaxProcedureByExternalId(procedures, 11), isNull);
    });

    test('legacy: externalId = id', () {
      final procedures = [
        _mp(77, {'id': 2, 'name': 'Impuesto de Industria y Comercio'}),
      ];
      expect(findTaxProcedureByExternalId(procedures, 2)!.id, 77);
    });
  });
}
