import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tramiapp_flutter/core/theme/design.dart';
import 'package:tramiapp_flutter/features/municipality/domain/municipality_model.dart';
import 'package:tramiapp_flutter/features/tramites/domain/info_tramite.dart';
import 'package:tramiapp_flutter/features/tramites/domain/integration_type_model.dart';
import 'package:tramiapp_flutter/features/tramites/domain/procedure_identity.dart';
import 'package:tramiapp_flutter/features/tutorial/domain/tutorial_content.dart';

InfoTramite _tramite(
  String key,
  ProcedureKind kind,
  TramiteAccion accion, {
  bool active = true,
}) => InfoTramite(
  nombre: key,
  icono: 'assets/images/icopredial.svg',
  color: Colors.white,
  accion: accion,
  idtramite: key.hashCode,
  isActive: active,
  category: kind == ProcedureKind.tax
      ? TramiteCategory.main
      : TramiteCategory.other,
  key: key,
  kind: kind,
);

final _predialApp = _tramite(
  'PREDIAL',
  ProcedureKind.tax,
  const NavegarAConsultaImpuesto(
    entityCode: 'E',
    queryFields: [],
    taxId: 1,
    dataPolicyUrl: '',
    privacyPolicyUrl: '',
  ),
);
final _industriaPsv = _tramite(
  'ICA',
  ProcedureKind.tax,
  const NavegarAPagoSinValidacion(
    taxId: 2,
    taxName: 'ICA',
    entityCode: 'E',
    dataPolicyUrl: '',
    privacyPolicyUrl: '',
  ),
);
final _reteIcaPortal = _tramite(
  'RETE_ICA',
  ProcedureKind.tax,
  const AbrirUrl('https://portal.gov.co'),
);
final _pqrsdfApp = _tramite('PQRSDF', ProcedureKind.pqrsdf, const ShowPqrds());
final _pqrsdfPortal = _tramite(
  'PQRSDF',
  ProcedureKind.pqrsdf,
  const AbrirUrlDirecto('https://pqrs.gov.co'),
);
final _panic = _tramite(
  'BOTON_PANICO',
  ProcedureKind.panicButton,
  const AbrirBotonPanico('https://wa.me/1', ''),
);

TramiteAccion get _certAction => const NavegarANativo('/cert');

MunicipalityModel _municipality(List<InfoTramite> tramites) =>
    MunicipalityModel(
      idMunicipio: 81,
      codigoEntidad: 'E',
      nombreMunicipio: 'Alcaldía de Rionegro',
      departamento: 'Antioquia',
      design: Design.fromThemeHex(
        alcaldiaName: 'Alcaldía de Rionegro',
        shieldUrl: '',
        primaryColor: '0xFF005B8C',
      ),
      tipoIntegracion: const TramitesporAPP(
        codigoEntidad: 'E',
        campoConsulta: [],
      ),
      domain: '',
      bank: '',
      privacyPolicyUrl: '',
      dataPolicyUrl: '',
      newsUrl: '',
      tramitesPrincipales: tramites
          .where((t) => t.category == TramiteCategory.main)
          .toList(),
      otrosTramites: tramites
          .where((t) => t.category == TramiteCategory.other)
          .toList(),
    );

String _route(List<InfoTramite> tramites, {bool hasSession = false}) =>
    buildTutorialContent(_municipality(tramites), hasSession: hasSession).route;

void main() {
  test('alcaldía con impuestos en la app y con sesión (recorrido A)', () {
    final certs = [
      for (var i = 0; i < 3; i++)
        _tramite('CERT_$i', ProcedureKind.certificate, _certAction),
    ];
    expect(
      _route([_predialApp, _pqrsdfApp, ...certs], hasSession: true),
      '1-2A-3A-4-5-6A',
    );
  });

  test('alcaldía solo con portal y sin sesión (recorrido B)', () {
    final cert = _tramite('CERT', ProcedureKind.certificate, _certAction);
    expect(_route([_reteIcaPortal, cert]), '1-2B-3B-4-6B-7');
  });

  test('basta un impuesto en la app (PSV) para el recorrido "en la app"', () {
    expect(
      _route([_reteIcaPortal, _industriaPsv], hasSession: true),
      '1-2A-3A-6A',
    );
  });

  test('sin impuestos no sale la tarjeta de impuestos', () {
    expect(_route([], hasSession: true), '1-3B-6B');
  });

  test('un impuesto «en desarrollo» no cuenta como pago en la app', () {
    final inactive = _tramite(
      'PREDIAL',
      ProcedureKind.tax,
      _predialApp.accion,
      active: false,
    );
    expect(_route([inactive, _reteIcaPortal]), '1-2B-3B-6B-7');
  });

  test('la guía de PQRSDF solo sale con el módulo de la app', () {
    final content = buildTutorialContent(
      _municipality([_predialApp, _pqrsdfPortal]),
      hasSession: true,
    );
    expect(content.route, '1-2A-3A-4-6A');
    // La 4 sí la menciona: el trámite está, aunque sea por enlace.
    expect(content.tramitesIncludePqrsdf, isTrue);
  });

  test('la tarjeta 4 deja fuera impuestos y botón de pánico, máximo 6', () {
    final certs = [
      for (var i = 0; i < 8; i++)
        _tramite('CERT_$i', ProcedureKind.certificate, _certAction),
    ];
    final content = buildTutorialContent(
      _municipality([_predialApp, _panic, ...certs]),
      hasSession: true,
    );
    expect(content.tramites, hasLength(kTutorialMaxTramites));
    expect(
      content.tramites.map((t) => t.kind),
      everyElement(ProcedureKind.certificate),
    );
    expect(content.tramitesIncludePqrsdf, isFalse);
  });

  test('el ícono de la 2B es el del primer impuesto por portal', () {
    final content = buildTutorialContent(
      _municipality([_reteIcaPortal]),
      hasSession: false,
    );
    expect(content.portalTaxTramite?.key, 'RETE_ICA');
    expect(content.alcaldia, 'Alcaldía de Rionegro');
  });
}
