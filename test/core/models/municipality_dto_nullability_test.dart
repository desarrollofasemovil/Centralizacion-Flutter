import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/municipalities_dto.dart';
import 'package:tramiapp_flutter/core/models/municipality.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/core/theme/color_parser.dart';
import 'package:tramiapp_flutter/features/tramites/application/tramite_mappers.dart';

/// `GetInfoBy{id}` con datos completos, con la forma real de la API
/// (`GetMunicipalitysDto.cs`). Datos sintéticos: el payload real de producción
/// trae credenciales Fintech que no deben vivir en el repo.
Map<String, dynamic> _fullPayload() => {
  'id': 14,
  'name': 'Amagá',
  'entityCode': '05030',
  'isActive': true,
  'domain': 'amaga-antioquia.gov.co',
  'userFintech': 'usuario',
  'passwordFintech': 'clave',
  'dataPrivacy': 'https://amaga.gov.co/privacidad',
  'dataProcessingPrivacy': 'https://amaga.gov.co/datos',
  'latitude': '6.0386',
  'longitude': '-75.7022',
  'emailMunicipalities': 'contacto@amaga.gov.co',
  'emailPanic': 'panico@amaga.gov.co',
  'phone': '6048471020',
  'bank': {'nameBank': 'Bancolombia'},
  'idShield': {
    'nameOfMunicipality': 'Amagá',
    'url': 'https://cdn.test/escudo-amaga.png',
  },
  'department': {'id': 5, 'name': 'Antioquia'},
  'theme': {
    'nameTheme': 'Amagá',
    'backGroundColor': '0xFFF3F4F6',
    'primaryColor': '0xFF1A5A8C',
    'secondaryColor': '0xFF4364CD',
    'secondaryColorBlack': '0xFFFFFFFF',
    'onPrimaryColorLight': '0xFFFFFFFF',
    'onPrimaryColorDark': '0xFF000000',
  },
  'courses': [
    {
      'id': 3,
      'name': 'Cursos',
      'get': 'https://c/get',
      'post': 'https://c/post',
      'isActive': true,
    },
  ],
  'sportsFacilities': [
    {
      'id': 4,
      'name': 'Escenarios',
      'get': 'https://v/get',
      'isActive': true,
      'calendaryPost': 'https://v/cal',
      'reservationPost': 'https://v/res',
    },
  ],
  'municipalityProcedures': [
    {
      'id': 1,
      'integrationType': '',
      'isActive': true,
      'procedures': {'id': 4, 'name': 'PQRSDF'},
    },
    {
      'id': 2,
      'integrationType': 'psv',
      'isActive': true,
      'procedures': {'id': 1, 'name': 'Impuesto Predial Unificado'},
    },
  ],
  'municipalitySocialMedia': [
    {
      'id': 1,
      'url': 'https://facebook.com/amaga',
      'isActive': true,
      'socialMediaType': {'id': 1, 'name': 'Facebook'},
    },
  ],
  'queryFields': [
    {'id': 1, 'fieldName': 'Ficha catastral', 'queryFieldType': 'text'},
  ],
  'newsByMunicipalities': [
    {'id': 1, 'getUrlNew': 'https://amaga.gov.co/noticias', 'idMunicipality': 14},
  ],
};

/// Lo que el wizard del dashboard ya puede crear: todo lo nullable en `null`,
/// incluidos los objetos anidados y los campos dentro de las listas.
Map<String, dynamic> _nullPayload() => {
  'id': 74,
  'name': null,
  'entityCode': null,
  'isActive': null,
  'domain': null,
  'userFintech': null,
  'passwordFintech': null,
  'dataPrivacy': null,
  'dataProcessingPrivacy': null,
  'latitude': null,
  'longitude': null,
  'emailMunicipalities': null,
  'emailPanic': null,
  'phone': null,
  'bank': null,
  'idShield': null,
  'department': null,
  'theme': null,
  'courses': [
    {'id': 3, 'name': null, 'get': null, 'post': null, 'isActive': null},
  ],
  'sportsFacilities': [
    {
      'id': 4,
      'name': null,
      'get': null,
      'isActive': null,
      'calendaryPost': null,
      'reservationPost': null,
    },
  ],
  'municipalityProcedures': [
    {'id': 1, 'integrationType': null, 'isActive': null, 'procedures': null},
    {
      'id': 2,
      'integrationType': null,
      'isActive': true,
      'procedures': {'id': 4, 'name': null},
    },
  ],
  'municipalitySocialMedia': [
    {'id': 1, 'url': null, 'isActive': null, 'socialMediaType': null},
  ],
  'queryFields': [
    {'id': 1, 'fieldName': null, 'queryFieldType': null},
  ],
  'newsByMunicipalities': [
    {'id': 1, 'getUrlNew': null, 'idMunicipality': null},
  ],
};

void main() {
  group('MunicipalityDTO — datos completos (sin cambios de comportamiento)', () {
    test('parsea y mapea al dominio como siempre', () {
      final dto = MunicipalityDTO.fromJson(_fullPayload());
      final model = dto.toDomainModel();

      expect(dto.name, 'Amagá');
      expect(dto.bank.nameBank, 'Bancolombia');
      expect(dto.idShield.url, 'https://cdn.test/escudo-amaga.png');
      expect(dto.department.name, 'Antioquia');
      expect(dto.courses.single.isActive, isTrue);
      expect(dto.sportsFacilities.single.reservationPost, 'https://v/res');

      expect(model.idMunicipio, 14);
      expect(model.nombreMunicipio, 'Alcaldía de Amagá');
      expect(model.departamento, 'Antioquia');
      expect(model.bank, 'Bancolombia');
      expect(model.design.escudoUrl, 'https://cdn.test/escudo-amaga.png');
      expect(model.design.primaryColor, const Color(0xFF1A5A8C));
      expect(model.design.secondaryColor, const Color(0xFF4364CD));
      expect(model.design.onPrimaryColorLight, const Color(0xFFFFFFFF));
      expect(model.latitude, 6.0386);
      expect(model.phone, '6048471020');
      expect(model.newsUrl, 'https://amaga.gov.co/noticias');
      expect(model.socialLinks, hasLength(1));
      expect(
        [...model.tramitesPrincipales, ...model.otrosTramites]
            .map((t) => t.nombre),
        containsAll(['PQRSDF', 'Impuesto Predial Unificado']),
      );
    });
  });

  group('MunicipalityDTO — nulos en todo lo nullable', () {
    test('parsea sin lanzar', () {
      expect(() => MunicipalityDTO.fromJson(_nullPayload()), returnsNormally);
    });

    test('el municipio abre con los fallbacks de siempre', () {
      final dto = MunicipalityDTO.fromJson(_nullPayload());
      final model = dto.toDomainModel();

      expect(dto.name, '');
      expect(dto.bank.nameBank, '');
      expect(dto.department.name, '');
      expect(dto.isActive, isFalse);
      // Sin `theme`: colores grises (y negro/blanco en los "on") de parseColor.
      expect(model.design.primaryColor, kColorFallback);
      expect(model.design.secondaryColor, kColorFallback);
      expect(model.design.onPrimaryColorLight, const Color(0xFF000000));
      expect(model.design.onPrimaryColorDark, const Color(0xFFFFFFFF));
      // Sin `idShield`: URL vacía (el header muestra el ícono de respaldo).
      expect(model.design.escudoUrl, '');
      expect(model.phone, isNull);
      expect(model.latitude, isNull);
    });

    test('los anidados nulos no rompen y quedan inactivos o vacíos', () {
      final dto = MunicipalityDTO.fromJson(_nullPayload());

      final procedureWithoutType = dto.municipalityProcedures.first;
      expect(procedureWithoutType.procedures.id, 0);
      expect(procedureWithoutType.integrationType, '');
      expect(procedureWithoutType.isActive, isFalse);
      expect(dto.municipalitySocialMedia.single.socialMediaType.name, '');
      expect(dto.courses.single.isActive, isFalse);
      expect(dto.sportsFacilities.single.get, '');
      expect(dto.queryFields.single.fieldName, '');
      expect(dto.newsByMunicipalities.single.url, '');
    });

    test('listas nulas se leen vacías', () {
      final json = _nullPayload()
        ..['courses'] = null
        ..['sportsFacilities'] = null
        ..['municipalityProcedures'] = null
        ..['municipalitySocialMedia'] = null
        ..['queryFields'] = null
        ..['newsByMunicipalities'] = null;

      final dto = MunicipalityDTO.fromJson(json);
      final model = dto.toDomainModel();

      expect(dto.courses, isEmpty);
      expect(dto.municipalityProcedures, isEmpty);
      expect(model.tramitesPrincipales, isEmpty);
      expect(model.socialLinks, isEmpty);
    });
  });

  group('MunicipalityDTO.phone', () {
    test('string (contrato actual de la API)', () {
      final dto = MunicipalityDTO.fromJson(
        _fullPayload()..['phone'] = '3001234567',
      );
      expect(dto.phone, '3001234567');
    });

    test('número (entornos con el contrato viejo) se lee como string', () {
      final dto = MunicipalityDTO.fromJson(_fullPayload()..['phone'] = 6041234);
      expect(dto.phone, '6041234');
    });
  });

  group('listas de municipios', () {
    test('ByDepartamet_{id}: nulos se leen vacíos e inactivos', () {
      final m = Municipality.fromJson({
        'id': 74,
        'name': null,
        'domain': null,
        'isActive': null,
      });
      expect(m.name, '');
      expect(m.domain, '');
      expect(m.isActive, isFalse);
    });

    test('GetMunicipality: nombre nulo se lee vacío', () {
      final m = MunicipalitiesDTO.fromJson({'id': 14, 'name': null});
      expect(m.name, '');
    });
  });
}
