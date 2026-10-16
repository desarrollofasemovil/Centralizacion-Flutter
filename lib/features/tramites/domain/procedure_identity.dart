import '../../../core/models/municipality_procedure.dart';
import '../../../core/models/procedures.dart';

/// Qué es un trámite y qué módulo de la app lo atiende (`procedures.kind`).
///
/// Cómo lo ofrece cada alcaldía (en la app o por enlace) no es un tipo: lo dice
/// `integrationType` (un valor `http(s)` es el canal enlace externo).
enum ProcedureKind {
  tax('TAX'),
  certificate('CERTIFICATE'),
  pqrsdf('PQRSDF'),
  publicServices('PUBLIC_SERVICES'),
  courses('COURSES'),
  venues('VENUES'),
  panicButton('PANIC_BUTTON'),

  /// Sin módulo en la app: siempre es un enlace.
  other('OTHER');

  const ProcedureKind(this.apiValue);

  final String apiValue;

  /// `null` para un valor que esta versión no conoce (compatibilidad hacia
  /// adelante: el trámite se oculta, nunca rompe).
  static ProcedureKind? tryParse(String? value) {
    if (value == null) return null;
    final normalized = value.trim().toUpperCase();
    for (final kind in values) {
      if (kind.apiValue == normalized) return kind;
    }
    return null;
  }
}

/// Códigos de los trámites a los que la app da un comportamiento propio. Los
/// genera el API; cualquier otro código usa el comportamiento de su `kind`.
abstract final class ProcedureCodes {
  static const predial = 'PREDIAL';
  static const ica = 'ICA';
  static const declaracion = 'DECLARACION';
  static const pqrsdf = 'PQRSDF';
  static const serviciosPublicos = 'SERVICIOS_PUBLICOS';
  static const vehiculos = 'VEHICULOS';
  static const reteIca = 'RETE_ICA';
  static const cursos = 'CURSOS';
  static const reservaEspacios = 'RESERVA_ESPACIOS';
  static const botonPanico = 'BOTON_PANICO';
  static const certResidencia = 'CERT_RESIDENCIA';
  static const certPazSalvo = 'CERT_PAZ_SALVO';
  static const certTurismo = 'CERT_TURISMO';
  static const certUsoSuelo = 'CERT_USO_SUELO';
}

/// Identidad resuelta de un trámite del catálogo.
class ProcedureIdentity {
  const ProcedureIdentity({
    required this.kind,
    this.code,
    this.externalId,
    this.gatewayTaxId,
  });

  final ProcedureKind kind;

  /// `null` si el API sirvió `kind` sin `code` (usa el comportamiento genérico).
  final String? code;

  /// Id para los servicios externos; `null` si el API no lo sirvió.
  final int? externalId;

  /// `IDImpuesto` de la pasarela (solo certificados); `null` = no se puede pagar.
  final int? gatewayTaxId;

  @override
  bool operator ==(Object other) =>
      other is ProcedureIdentity &&
      other.kind == kind &&
      other.code == code &&
      other.externalId == externalId &&
      other.gatewayTaxId == gatewayTaxId;

  @override
  int get hashCode => Object.hash(kind, code, externalId, gatewayTaxId);

  @override
  String toString() =>
      'ProcedureIdentity($kind, $code, externalId: $externalId, '
      'gatewayTaxId: $gatewayTaxId)';
}

/// Tabla legacy por `Procedures.Id` de producción. **Es el único lugar de la app
/// que conoce los ids 1–14**, y solo se usa cuando la respuesta no trae
/// identidad (producción antes del despliegue del API).
const Map<int, (String, ProcedureKind)> _legacyById = {
  1: (ProcedureCodes.predial, ProcedureKind.tax),
  2: (ProcedureCodes.ica, ProcedureKind.tax),
  3: (ProcedureCodes.declaracion, ProcedureKind.tax),
  4: (ProcedureCodes.pqrsdf, ProcedureKind.pqrsdf),
  5: (ProcedureCodes.serviciosPublicos, ProcedureKind.publicServices),
  6: (ProcedureCodes.vehiculos, ProcedureKind.tax),
  7: (ProcedureCodes.reteIca, ProcedureKind.tax),
  8: (ProcedureCodes.cursos, ProcedureKind.courses),
  9: (ProcedureCodes.reservaEspacios, ProcedureKind.venues),
  10: (ProcedureCodes.botonPanico, ProcedureKind.panicButton),
  11: (ProcedureCodes.certResidencia, ProcedureKind.certificate),
  12: (ProcedureCodes.certPazSalvo, ProcedureKind.certificate),
  13: (ProcedureCodes.certTurismo, ProcedureKind.certificate),
  14: (ProcedureCodes.certUsoSuelo, ProcedureKind.certificate),
};

/// `IDImpuesto` de Bancolombia PSE por certificado, mientras el API no sirva
/// `gatewayTaxId` (Fase 0).
const Map<String, int> _gatewayTaxIdByCode = {
  ProcedureCodes.certResidencia: 43,
  ProcedureCodes.certPazSalvo: 26,
  ProcedureCodes.certTurismo: 269,
  ProcedureCodes.certUsoSuelo: 20,
};

/// `true` si algún trámite de la respuesta trae `kind`. Si ninguno lo trae, la
/// respuesta es de un entorno sin identidad y se usa la tabla legacy por id.
bool responseHasProcedureIdentity(Iterable<MunicipalityProcedure> procedures) =>
    procedures.any((p) => p.procedures.kind != null);

/// Resuelve qué es un trámite. `null` = el trámite no se muestra.
///
/// - Con identidad en la respuesta: `kind`/`code`/`externalId` tal como llegan;
///   un trámite sin `kind` (o con uno desconocido) se oculta, **nunca** se
///   resuelve por id (en desarrollo el 8 es una fila de prueba, no Cursos).
/// - Sin identidad en toda la respuesta: tabla legacy por id, `externalId = id`.
ProcedureIdentity? resolveProcedure(
  Procedures p, {
  required bool responseHasIdentity,
}) {
  if (responseHasIdentity) {
    final kind = ProcedureKind.tryParse(p.kind);
    if (kind == null) return null;
    return ProcedureIdentity(
      kind: kind,
      code: p.code,
      externalId: p.externalId,
      gatewayTaxId: _gatewayTaxId(p.gatewayTaxId, p.code),
    );
  }

  final legacy = _legacyById[p.id];
  if (legacy == null) return null;
  final (code, kind) = legacy;
  return ProcedureIdentity(
    kind: kind,
    code: code,
    externalId: p.externalId ?? p.id,
    gatewayTaxId: _gatewayTaxId(p.gatewayTaxId, code),
  );
}

int? _gatewayTaxId(int? served, String? code) =>
    served ?? (code == null ? null : _gatewayTaxIdByCode[code]);

/// Trámite de impuesto de la alcaldía cuyo `externalId` es el `Id_Impuesto` de
/// apidatamovil (`tax.taxId`). Para el historial se usa el `id` de la fila
/// devuelta (`MunicipalityProcedure.id`), no el del catálogo.
MunicipalityProcedure? findTaxProcedureByExternalId(
  List<MunicipalityProcedure> procedures,
  int externalTaxId,
) {
  final hasIdentity = responseHasProcedureIdentity(procedures);
  for (final mp in procedures) {
    final identity = resolveProcedure(
      mp.procedures,
      responseHasIdentity: hasIdentity,
    );
    if (identity?.kind == ProcedureKind.tax &&
        identity!.externalId == externalTaxId) {
      return mp;
    }
  }
  return null;
}
