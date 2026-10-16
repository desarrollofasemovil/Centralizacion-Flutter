import '../../tramites/domain/procedure_identity.dart';

/// Ícono de un certificado cuyo `code` la app no conoce.
const kGenericCertificateIcon = 'assets/images/icocertresidencia.svg';

/// Si un certificado se ofrece en la app (decisión de Brayan, 2026-10-14):
/// `CERT_TURISMO` siempre (su valor sale de la edad y Remote Config); el resto
/// solo cuando la alcaldía le puso valor. Sin valor se oculta: nunca cae en la
/// consulta de impuestos ni en otra pantalla.
bool isCertificateOffered({required String? code, required String value}) =>
    code == ProcedureCodes.certTurismo || value.trim().isNotEmpty;

/// Certificado que abre el asistente, ya resuelto por `resolveProcedure`.
///
/// Viaja como `extra` de la ruta (no como segmentos del path: el valor del
/// certificado puede ir vacío y rompería el match).
class CertificateProcedure {
  const CertificateProcedure({
    required this.municipalityProcedureId,
    required this.entityCode,
    required this.name,
    required this.externalId,
    required this.gatewayTaxId,
    required this.value,
    this.code,
  });

  /// `MunicipalityProcedure.id` de la fila del municipio (para el historial de
  /// pagos), no el id del catálogo.
  final int municipalityProcedureId;

  final String entityCode;

  /// Nombre del trámite en el catálogo (título si el `code` no es conocido).
  final String name;
  final String? code;

  /// `IDTramite` de tramitesservices.
  final int externalId;

  /// `IDImpuesto` de la pasarela.
  final int gatewayTaxId;

  /// Valor del certificado (`integrationType`); vacío en `CERT_TURISMO`.
  final String value;

  /// `CERT_TURISMO` se cobra por edad y tipo de documento.
  bool get isAgePriced => code == ProcedureCodes.certTurismo;

  String get title => switch (code) {
    ProcedureCodes.certResidencia => 'Certificado de Residencia',
    ProcedureCodes.certPazSalvo => 'Certificado de Paz y Salvo',
    ProcedureCodes.certTurismo => 'Contribución al turismo',
    ProcedureCodes.certUsoSuelo => 'Concepto de Uso del Suelo',
    _ => name.trim().isNotEmpty ? name : 'Certificado',
  };

  String get iconPath => switch (code) {
    ProcedureCodes.certResidencia => 'assets/images/icocertresidencia.svg',
    ProcedureCodes.certPazSalvo => 'assets/images/icocertpazysalvo.svg',
    ProcedureCodes.certTurismo => 'assets/images/icocertourism.svg',
    ProcedureCodes.certUsoSuelo => 'assets/images/icoconceptusodelsuelo.svg',
    _ => kGenericCertificateIcon,
  };

  @override
  bool operator ==(Object other) =>
      other is CertificateProcedure &&
      other.municipalityProcedureId == municipalityProcedureId &&
      other.entityCode == entityCode &&
      other.name == name &&
      other.code == code &&
      other.externalId == externalId &&
      other.gatewayTaxId == gatewayTaxId &&
      other.value == value;

  @override
  int get hashCode => Object.hash(
    municipalityProcedureId,
    entityCode,
    name,
    code,
    externalId,
    gatewayTaxId,
    value,
  );
}
