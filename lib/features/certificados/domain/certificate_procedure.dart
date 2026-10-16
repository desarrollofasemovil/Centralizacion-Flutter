import '../../tramites/domain/procedure_identity.dart';

/// Ícono de un certificado cuyo `code` la app no conoce.
const kGenericCertificateIcon = 'assets/images/icocertresidencia.svg';

/// Certificado que abre el asistente, ya resuelto por `resolveProcedure`.
///
/// Viaja como `extra` de la ruta (no como segmentos del path: el valor del
/// certificado puede ir vacío y rompería el match).
class CertificateProcedure {
  const CertificateProcedure({
    required this.entityCode,
    required this.name,
    required this.externalId,
    required this.gatewayTaxId,
    required this.value,
    this.code,
  });

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
      other.entityCode == entityCode &&
      other.name == name &&
      other.code == code &&
      other.externalId == externalId &&
      other.gatewayTaxId == gatewayTaxId &&
      other.value == value;

  @override
  int get hashCode =>
      Object.hash(entityCode, name, code, externalId, gatewayTaxId, value);
}
