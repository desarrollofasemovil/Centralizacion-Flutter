import '../../tramites/domain/info_tramite.dart';
import '../../tramites/domain/procedure_identity.dart';

/// Lo que la medición de un portal externo necesita del trámite. Es lo que se
/// guarda en disco con la visita, así que solo lleva datos simples (no el
/// [InfoTramite] completo, con su ícono, color y acción).
class PortalTramite {
  const PortalTramite({
    required this.codigo,
    required this.id,
    required this.nombre,
    required this.isTax,
  });

  factory PortalTramite.fromInfoTramite(InfoTramite tramite) => PortalTramite(
    codigo: tramite.key,
    id: tramite.idtramite,
    nombre: tramite.nombre,
    isTax: tramite.kind == ProcedureKind.tax,
  );

  /// `key` del trámite (el `code` del catálogo, estable entre entornos).
  final String codigo;
  final int id;
  final String nombre;

  /// Impuesto: la encuesta pregunta por un pago, así que solo aplica a estos.
  final bool isTax;

  Map<String, Object> toJson() => {
    'codigo': codigo,
    'id': id,
    'nombre': nombre,
    'isTax': isTax,
  };

  static PortalTramite fromJson(Map<String, dynamic> json) => PortalTramite(
    codigo: json['codigo'] as String,
    id: json['id'] as int,
    nombre: json['nombre'] as String,
    isTax: json['isTax'] as bool,
  );
}

/// Una visita a un portal externo en curso.
class PortalVisit {
  const PortalVisit({
    required this.tramite,
    required this.municipalityId,
    required this.url,
    required this.openedAt,
  });

  final PortalTramite tramite;
  final int municipalityId;
  final String url;
  final DateTime openedAt;

  Map<String, Object> toJson() => {
    'tramite': tramite.toJson(),
    'municipalityId': municipalityId,
    'url': url,
    'openedAt': openedAt.millisecondsSinceEpoch,
  };

  static PortalVisit fromJson(Map<String, dynamic> json) => PortalVisit(
    tramite: PortalTramite.fromJson(json['tramite'] as Map<String, dynamic>),
    municipalityId: json['municipalityId'] as int,
    url: json['url'] as String,
    openedAt: DateTime.fromMillisecondsSinceEpoch(json['openedAt'] as int),
  );
}
