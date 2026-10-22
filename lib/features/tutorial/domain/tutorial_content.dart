import 'dart:ui';

import '../../municipality/domain/municipality_model.dart';
import '../../tramites/domain/info_tramite.dart';
import '../../tramites/domain/procedure_identity.dart';

/// Tarjetas del tutorial de primer uso (plan
/// `docs/superpowers/plans/2026-10-21-tutorial-primer-uso.md`). [id] es el
/// número del diseño en Claude Design; también va en la analítica (`tarjeta`)
/// y es la clave de sus textos en Remote Config.
enum TutorialCard {
  welcome('1'),
  taxesInApp('2A'),
  taxesPortal('2B'),
  remindersInApp('3A'),
  remindersPortal('3B'),
  tramites('4'),
  pqrsdf('5'),
  historyInApp('6A'),
  historyPortal('6B'),
  account('7');

  const TutorialCard(this.id);

  final String id;
}

/// Máximo de trámites en la tarjeta 4 (dos filas de tres, como en el diseño).
const kTutorialMaxTramites = 6;

/// Lo que el tutorial necesita de la alcaldía, ya resuelto.
class TutorialContent {
  const TutorialContent({
    required this.alcaldia,
    required this.shieldUrl,
    required this.primary,
    required this.cards,
    this.tramites = const [],
    this.pqrsdfTramite,
    this.portalTaxTramite,
  });

  /// «Alcaldía de {nombre}», tal como lo arma el mapper.
  final String alcaldia;
  final String shieldUrl;

  /// Primario de la alcaldía tal como llega del backend (sin ajustar contraste).
  final Color primary;
  final List<TutorialCard> cards;

  /// Trámites de la tarjeta 4.
  final List<InfoTramite> tramites;

  /// Ícono de la tarjeta 5 (el mismo de la Home).
  final InfoTramite? pqrsdfTramite;

  /// Ícono de la tarjeta 2B: el primer impuesto por portal.
  final InfoTramite? portalTaxTramite;

  /// Si el texto de la tarjeta 4 nombra las PQRSDF.
  bool get tramitesIncludePqrsdf =>
      tramites.any((t) => t.kind == ProcedureKind.pqrsdf);

  /// Recorrido para la analítica, p. ej. `1-2A-3A-4-5-6A`.
  String get route => cards.map((c) => c.id).join('-');
}

/// Decide qué tarjetas salen para esta alcaldía (hoja de especificaciones del
/// diseño):
///
/// ```
/// [ '1',
///   pagosEnApp ? '2A' : '2B',   // sin impuestos, no sale
///   pagosEnApp ? '3A' : '3B',
///   if (tramites.isNotEmpty) '4',
///   if (pqrsdfEnApp) '5',
///   pagosEnApp ? '6A' : '6B',
///   if (!sesion) '7' ]
/// ```
///
/// "En la app" = el impuesto se consulta o paga dentro de la app; uno cuyo
/// `integrationType` es una URL es "por portal". Solo cuentan los trámites
/// activos: uno «en desarrollo» no se puede usar todavía.
TutorialContent buildTutorialContent(
  MunicipalityModel municipality, {
  required bool hasSession,
}) {
  final active = [
    ...municipality.tramitesPrincipales,
    ...municipality.otrosTramites,
  ].where((t) => t.isActive).toList();

  final taxes = active.where((t) => t.kind == ProcedureKind.tax).toList();
  final paysInApp = taxes.any(
    (t) =>
        t.accion is NavegarAConsultaImpuesto ||
        t.accion is NavegarAPagoSinValidacion,
  );
  InfoTramite? portalTax;
  for (final t in taxes) {
    if (t.accion is AbrirUrl) {
      portalTax = t;
      break;
    }
  }

  // Lo que no es un impuesto: certificados, PQRSDF, cursos, escenarios,
  // servicios públicos… El botón de pánico no es un trámite que se "haga".
  final tramites = active
      .where(
        (t) =>
            t.kind != ProcedureKind.tax && t.kind != ProcedureKind.panicButton,
      )
      .take(kTutorialMaxTramites)
      .toList();

  // La guía habla de radicado y de PQRSDF anónima: es la del módulo de la app.
  InfoTramite? pqrsdf;
  for (final t in active) {
    if (t.kind == ProcedureKind.pqrsdf && t.accion is ShowPqrds) {
      pqrsdf = t;
      break;
    }
  }

  final cards = <TutorialCard>[
    TutorialCard.welcome,
    if (taxes.isNotEmpty)
      paysInApp ? TutorialCard.taxesInApp : TutorialCard.taxesPortal,
    paysInApp ? TutorialCard.remindersInApp : TutorialCard.remindersPortal,
    if (tramites.isNotEmpty) TutorialCard.tramites,
    if (pqrsdf != null) TutorialCard.pqrsdf,
    paysInApp ? TutorialCard.historyInApp : TutorialCard.historyPortal,
    if (!hasSession) TutorialCard.account,
  ];

  return TutorialContent(
    alcaldia: municipality.nombreMunicipio,
    shieldUrl: municipality.design.escudoUrl,
    primary: municipality.design.primaryColor,
    cards: cards,
    tramites: tramites,
    pqrsdfTramite: pqrsdf,
    portalTaxTramite: portalTax,
  );
}
