import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/models/municipality_dto.dart';
import 'package:tramiapp_flutter/features/municipality/domain/municipality_model.dart';
import 'package:tramiapp_flutter/features/tramites/application/tramite_mappers.dart';
import 'package:tramiapp_flutter/features/tramites/domain/info_tramite.dart';
import 'package:tramiapp_flutter/features/tramites/domain/integration_type_model.dart';
import 'package:tramiapp_flutter/features/tramites/domain/procedure_identity.dart';

/// Trámite del catálogo como lo sirve `GetInfoBy{id}`.
Map<String, dynamic> _proc(
  int rowId,
  int id,
  String name, {
  String integrationType = '',
  String? code,
  String? kind,
  int? externalId,
}) => {
  'id': rowId,
  'integrationType': integrationType,
  'isActive': true,
  'procedures': {
    'id': id,
    'name': name,
    'code': ?code,
    'kind': ?kind,
    'externalId': ?externalId,
  },
};

MunicipalityDTO _dto(
  List<Map<String, dynamic>> procedures, {
  String entityCode = '05030',
  bool withCourses = false,
  bool withVenues = false,
}) => MunicipalityDTO.fromJson({
  'id': 81,
  'name': 'Prueba',
  'entityCode': entityCode,
  'isActive': true,
  'domain': 'prueba.gov.co',
  'userFintech': '',
  'passwordFintech': '',
  'emailPanic': 'panico@prueba.gov.co',
  'bank': {'nameBank': 'Bancolombia'},
  'idShield': {'nameOfMunicipality': 'Prueba', 'url': 'https://cdn/e.png'},
  'department': {'id': 5, 'name': 'Antioquia'},
  'theme': {
    'nameTheme': 'Prueba',
    'backGroundColor': '0xFFF3F4F6',
    'primaryColor': '0xFF1A5A8C',
    'secondaryColor': '0xFF4364CD',
    'secondaryColorBlack': '0xFFFFFFFF',
    'onPrimaryColorLight': '0xFFFFFFFF',
    'onPrimaryColorDark': '0xFF000000',
  },
  'courses': [
    if (withCourses)
      {'id': 3, 'name': 'Cursos', 'get': '', 'post': '', 'isActive': true},
  ],
  'sportsFacilities': [
    if (withVenues)
      {
        'id': 4,
        'name': 'Escenarios',
        'get': '',
        'isActive': true,
        'calendaryPost': '',
        'reservationPost': '',
      },
  ],
  'municipalityProcedures': procedures,
  'municipalitySocialMedia': <Map<String, dynamic>>[],
  'queryFields': <Map<String, dynamic>>[],
  'newsByMunicipalities': <Map<String, dynamic>>[],
});

List<InfoTramite> _tiles(MunicipalityModel m) => [
  ...m.tramitesPrincipales,
  ...m.otrosTramites,
];

InfoTramite? _tile(MunicipalityModel m, String name) =>
    _tiles(m).where((t) => t.nombre == name).firstOrNull;

/// Los 14 trámites originales con ids recreados (230–243) y su identidad.
List<Map<String, dynamic>> _recreatedCatalog({
  Map<String, String> values = const {},
}) {
  const rows = [
    ('Impuesto Predial Unificado', 'PREDIAL', 'TAX', 1),
    ('Impuesto de Industria y Comercio', 'ICA', 'TAX', 2),
    ('Declaración Industria y Comercio', 'DECLARACION', 'TAX', 3),
    ('PQRDSF', 'PQRSDF', 'PQRSDF', null),
    ('Servicios Públicos', 'SERVICIOS_PUBLICOS', 'PUBLIC_SERVICES', null),
    ('Impuesto Vehicular', 'VEHICULOS', 'TAX', 6),
    ('Retención de Industria y Comercio', 'RETE_ICA', 'TAX', 7),
    ('Cursos', 'CURSOS', 'COURSES', null),
    ('Reserva de espacios', 'RESERVA_ESPACIOS', 'VENUES', null),
    ('Botón de pánico', 'BOTON_PANICO', 'PANIC_BUTTON', null),
    ('Certificado de Residencia', 'CERT_RESIDENCIA', 'CERTIFICATE', 11),
    ('Certificado de Paz y Salvo', 'CERT_PAZ_SALVO', 'CERTIFICATE', 12),
    ('Contribución al Turismo', 'CERT_TURISMO', 'CERTIFICATE', 13),
    ('Concepto de Uso del Suelo', 'CERT_USO_SUELO', 'CERTIFICATE', 14),
  ];
  return [
    for (var i = 0; i < rows.length; i++)
      _proc(
        1000 + i,
        230 + i,
        rows[i].$1,
        code: rows[i].$2,
        kind: rows[i].$3,
        externalId: rows[i].$4,
        integrationType: values[rows[i].$2] ?? '',
      ),
  ];
}

/// El mismo catálogo con los ids originales 1–14 y sin identidad (producción).
List<Map<String, dynamic>> _legacyCatalog({
  Map<String, String> values = const {},
}) => [
  for (final p in _recreatedCatalog(values: values))
    {
      ...p,
      'procedures': {
        'id': (p['procedures'] as Map)['id'] - 229,
        'name': (p['procedures'] as Map)['name'],
      },
    },
];

/// Acción resumida para comparar entre catálogos.
String _describe(TramiteAccion a) => switch (a) {
  ShowPqrds() => 'pqrsdf',
  AbrirUrl(:final url) => 'url-form:$url',
  AbrirUrlDirecto(:final url) => 'url-direct:$url',
  NavegarANativo(:final ruta) => 'native:$ruta',
  AbrirBotonPanico(:final baseWhatsappUrl) => 'panic:$baseWhatsappUrl',
  NavegarAConsultaImpuesto(:final taxId) => 'tax-query:$taxId',
  NavegarACursos(:final courseId) => 'courses:$courseId',
  NavegarAvenues(:final venueId) => 'venues:$venueId',
  NavegarAPagoSinValidacion(:final taxId) => 'psv:$taxId',
  NavegarACertificado(:final certificate) =>
    'cert:${certificate.code}/${certificate.externalId}/'
        '${certificate.gatewayTaxId}/${certificate.value}',
};

void main() {
  group('motor de trámites', () {
    test(
      'ids recreados con códigos → mismas acciones que los ids originales',
      () {
        const values = {
          'ICA': 'psv',
          'CERT_RESIDENCIA': '9000',
          'CERT_PAZ_SALVO': '9000',
          'CERT_USO_SUELO': '9000',
          'BOTON_PANICO': 'https://wa.me/57300',
        };
        final recreated = _dto(
          _recreatedCatalog(values: values),
          withCourses: true,
          withVenues: true,
        ).toDomainModel();
        final legacy = _dto(
          _legacyCatalog(values: values),
          withCourses: true,
          withVenues: true,
        ).toDomainModel();

        Map<String, String> actions(MunicipalityModel m) => {
          for (final t in _tiles(m)) t.nombre: _describe(t.accion),
        };
        expect(actions(recreated), actions(legacy));
        expect(_tiles(recreated), hasLength(14));
        expect(actions(recreated), {
          'Impuesto Predial Unificado': 'tax-query:1',
          'Impuesto de Industria y Comercio': 'psv:2',
          'Declaración Industria y Comercio': 'tax-query:3',
          'PQRDSF': 'pqrsdf',
          'Servicios Públicos': 'native:/municipality/81/servicios-publicos',
          'Impuesto Vehicular': 'tax-query:6',
          'Retención de Industria y Comercio': 'tax-query:7',
          'Cursos': 'courses:3',
          'Reserva de espacios': 'venues:4',
          'Botón de pánico': 'panic:https://wa.me/57300',
          'Certificado de Residencia': 'cert:CERT_RESIDENCIA/11/43/9000',
          'Certificado de Paz y Salvo': 'cert:CERT_PAZ_SALVO/12/26/9000',
          'Contribución al Turismo': 'cert:CERT_TURISMO/13/269/',
          'Concepto de Uso del Suelo': 'cert:CERT_USO_SUELO/14/20/9000',
        });
        // Íconos por código, no por id.
        expect(
          _tile(recreated, 'Contribución al Turismo')!.icono,
          'assets/images/icocertourism.svg',
        );
        expect(_tile(recreated, 'Botón de pánico')!.color, kPanicButtonColor);
      },
    );

    test(
      'CERT_TURISMO sin valor → certificados, nunca consulta de impuesto',
      () {
        final m = _dto([
          _proc(
            50,
            9,
            'Contribución al Turismo',
            code: 'CERT_TURISMO',
            kind: 'CERTIFICATE',
            externalId: 13,
            integrationType: 'API',
          ),
          _proc(
            51,
            230,
            'Contribución al Turismo bis',
            code: 'CERT_TURISMO_2',
            kind: 'CERTIFICATE',
            externalId: 13,
          ),
        ]).toDomainModel();
        final tile = _tile(m, 'Contribución al Turismo')!;
        expect(tile.accion, isA<NavegarACertificado>());
        final cert = (tile.accion as NavegarACertificado).certificate;
        expect(cert.isAgePriced, isTrue);
        expect(cert.externalId, 13);
        expect(cert.gatewayTaxId, 269);
        // Certificado de código desconocido y sin valor: oculto.
        expect(_tile(m, 'Contribución al Turismo bis'), isNull);
      },
    );

    test('legacy: el 13 sin valor también va a certificados', () {
      final m = _dto([
        _proc(50, 13, 'Contribución al Turismo'),
      ]).toDomainModel();
      expect(
        _describe(_tile(m, 'Contribución al Turismo')!.accion),
        'cert:CERT_TURISMO/13/269/',
      );
    });

    test('certificado sin valor (no turismo) → oculto', () {
      final m = _dto([
        _proc(
          50,
          10,
          'Certificado de Residencia',
          code: 'CERT_RESIDENCIA',
          kind: 'CERTIFICATE',
          externalId: 11,
        ),
      ]).toDomainModel();
      expect(_tiles(m), isEmpty);
    });

    test('certificado sin id de pasarela (CERT_TEST) → oculto', () {
      final m = _dto([
        _proc(
          50,
          13,
          'Test',
          code: 'CERT_TEST',
          kind: 'CERTIFICATE',
          externalId: 14,
          integrationType: '9000',
        ),
      ]).toDomainModel();
      expect(_tiles(m), isEmpty);
    });

    test('pqrsdf / certificado con URL → enlace directo, sin formulario', () {
      final m = _dto([
        _proc(
          1,
          4,
          'PQRDSF',
          code: 'PQRSDF',
          kind: 'PQRSDF',
          integrationType: 'https://pqrs.gov.co',
        ),
        _proc(
          2,
          10,
          'Certificado de Residencia',
          code: 'CERT_RESIDENCIA',
          kind: 'CERTIFICATE',
          externalId: 11,
          integrationType: 'HTTPS://cert.gov.co',
        ),
        _proc(
          3,
          20,
          'Servicios Públicos',
          code: 'SERVICIOS_PUBLICOS',
          kind: 'PUBLIC_SERVICES',
          integrationType: 'http://sp.gov.co',
        ),
      ]).toDomainModel();
      expect(_tile(m, 'PQRDSF')!.accion, isA<AbrirUrlDirecto>());
      expect(
        _tile(m, 'Certificado de Residencia')!.accion,
        isA<AbrirUrlDirecto>(),
      );
      expect(_tile(m, 'Servicios Públicos')!.accion, isA<AbrirUrlDirecto>());
    });

    test('impuesto con URL → enlace con formulario de datos (AbrirUrl)', () {
      final m = _dto([
        _proc(
          1,
          230,
          'Impuesto Predial Unificado',
          code: 'PREDIAL',
          kind: 'TAX',
          externalId: 1,
          integrationType: 'https://predial.gov.co',
        ),
      ]).toDomainModel();
      final accion = _tile(m, 'Impuesto Predial Unificado')!.accion;
      expect(accion, isA<AbrirUrl>());
      expect((accion as AbrirUrl).url, 'https://predial.gov.co');
    });

    test('escenarios / cursos / pánico con valor http → su módulo', () {
      final m = _dto(
        [
          _proc(
            1,
            240,
            'Reservas',
            code: 'RESERVA_ESPACIOS',
            kind: 'VENUES',
            integrationType: 'https://sharepoint/base',
          ),
          _proc(
            2,
            241,
            'Cursos catálogo',
            code: 'CURSOS',
            kind: 'COURSES',
            integrationType: 'https://sharepoint/cursos',
          ),
          _proc(
            3,
            242,
            'Pánico',
            code: 'BOTON_PANICO',
            kind: 'PANIC_BUTTON',
            integrationType: 'https://wa.me/57300',
          ),
        ],
        withCourses: true,
        withVenues: true,
      ).toDomainModel();
      expect(_tile(m, 'Reservas')!.accion, isA<NavegarAvenues>());
      expect(_tile(m, 'Cursos catálogo')!.accion, isA<NavegarACursos>());
      expect(_tile(m, 'Pánico')!.accion, isA<AbrirBotonPanico>());
      // El trámite del catálogo y el tile sintético son el mismo: uno solo.
      expect(_tiles(m), hasLength(3));
    });

    test('escenarios sin sportsFacilities → oculto', () {
      final m = _dto([
        _proc(1, 240, 'Reservas', code: 'RESERVA_ESPACIOS', kind: 'VENUES'),
      ]).toDomainModel();
      expect(_tiles(m), isEmpty);
    });

    test('OTHER: con URL se abre directo, sin URL se oculta', () {
      final m = _dto([
        _proc(
          1,
          300,
          'Portal de empleo',
          code: 'PORTAL_EMPLEO',
          kind: 'OTHER',
          integrationType: 'https://empleo.gov.co',
        ),
        _proc(2, 301, 'Sin enlace', code: 'SIN_ENLACE', kind: 'OTHER'),
      ]).toDomainModel();
      final tile = _tile(m, 'Portal de empleo')!;
      expect(tile.accion, isA<AbrirUrlDirecto>());
      expect(tile.icono, 'assets/images/icoportal.svg');
      expect(tile.category, TramiteCategory.other);
      expect(_tile(m, 'Sin enlace'), isNull);
    });

    test('kind desconocido o ausente en respuesta con identidad → oculto', () {
      final m = _dto([
        _proc(1, 230, 'Predial', code: 'PREDIAL', kind: 'TAX', externalId: 1),
        _proc(2, 8, 'Tramite de prueba'),
        _proc(3, 99, 'Futuro', code: 'FUTURO', kind: 'FUTURE_KIND'),
      ]).toDomainModel();
      expect(_tiles(m).map((t) => t.nombre), ['Predial']);
    });

    test('código desconocido con kind conocido → comportamiento del kind', () {
      final m = _dto([
        _proc(
          1,
          250,
          'Impuesto de alumbrado',
          code: 'ALUMBRADO',
          kind: 'TAX',
          externalId: 21,
        ),
      ]).toDomainModel();
      final tile = _tile(m, 'Impuesto de alumbrado')!;
      expect(_describe(tile.accion), 'tax-query:21');
      expect(tile.category, TramiteCategory.main);
      expect(tile.icono, 'assets/images/icopredial.svg');
    });

    test(
      'dedupe: certificado 9 = CERT_TURISMO y el tile de escenarios conviven',
      () {
        final m = _dto(
          [
            _proc(
              50,
              9,
              'Contribución al Turismo',
              code: 'CERT_TURISMO',
              kind: 'CERTIFICATE',
              externalId: 13,
            ),
            _proc(51, 8, 'Prueba ocho', code: 'PQRSDF', kind: 'PQRSDF'),
          ],
          withCourses: true,
          withVenues: true,
        ).toDomainModel();
        final turismo = _tile(m, 'Contribución al Turismo')!;
        final venues = _tile(m, 'Reserva de espacios')!;
        expect(turismo.accion, isA<NavegarACertificado>());
        expect(turismo.icono, 'assets/images/icocertourism.svg');
        expect(venues.accion, isA<NavegarAvenues>());
        expect(venues.icono, 'assets/images/icoreservas.svg');
        expect(_tile(m, 'Cursos'), isNotNull);
        expect(_tile(m, 'Prueba ocho'), isNotNull);
      },
    );

    test('toIntegrationModel busca las URLs por código, no por nombre', () {
      final integration = _dto([
        _proc(
          1,
          230,
          'Impuesto Predial Unificado',
          code: 'PREDIAL',
          kind: 'TAX',
          externalId: 1,
          integrationType: 'https://predial',
        ),
        _proc(
          2,
          236,
          'Retención de Industria y Comercio',
          code: 'RETE_ICA',
          kind: 'TAX',
          externalId: 7,
          integrationType: 'https://reteica',
        ),
      ], entityCode: '').toIntegrationModel();
      expect(integration, isA<TramitesporURL>());
      final urls = integration as TramitesporURL;
      expect(urls.urlPredial, 'https://predial');
      expect(urls.urlReteIca, 'https://reteica');
      // Antes "Industria" casaba con la retención por nombre.
      expect(urls.urlIca, '');
    });

    test('ProcedureKind de los tiles', () {
      final m = _dto(_recreatedCatalog()).toDomainModel();
      expect(_tile(m, 'Impuesto Predial Unificado')!.kind, ProcedureKind.tax);
    });
  });
}
