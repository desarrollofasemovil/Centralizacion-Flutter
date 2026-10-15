import 'package:json_annotation/json_annotation.dart';

part 'procedures.g.dart';

/// Lectura tolerante de la identidad de los trámites: un tipo inesperado se lee
/// como `null` en vez de romper `GetInfoBy{id}` (la resolución lo oculta).
String? _stringOrNull(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int? _intOrNull(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

/// Trámite del catálogo (`municipalityProcedures[].procedures`).
///
/// `id` es la identity de la base: cambia entre entornos y cuando una fila se
/// recrea, así que **no decide comportamiento**. La identidad estable es
/// `code` + `kind` + `externalId` (todos opcionales: el API los omite cuando
/// son nulos). Se resuelven en `procedure_identity.dart`, nunca aquí.
@JsonSerializable()
class Procedures {
  @JsonKey(defaultValue: 0)
  final int id;
  @JsonKey(defaultValue: '')
  final String name;

  /// Identidad estable (`PREDIAL`, `CERT_TURISMO`…). La genera el API.
  @JsonKey(fromJson: _stringOrNull, includeIfNull: false)
  final String? code;

  /// Qué es el trámite (`TAX`, `CERTIFICATE`…), tal cual llega del API. Se
  /// guarda crudo para distinguir "no trae tipo" de "trae un tipo que esta
  /// versión no conoce"; `ProcedureKind.tryParse` lo interpreta.
  @JsonKey(fromJson: _stringOrNull, includeIfNull: false)
  final String? kind;

  /// Id que conocen los servicios externos (`Id_Impuesto` de apidatamovil,
  /// `IDTramite` de tramitesservices).
  @JsonKey(fromJson: _intOrNull, includeIfNull: false)
  final int? externalId;

  /// `IDImpuesto` de la pasarela para los certificados. Llega con la Fase 0
  /// (prompt 04); mientras tanto se usan las constantes por `code`.
  @JsonKey(fromJson: _intOrNull, includeIfNull: false)
  final int? gatewayTaxId;

  Procedures({
    required this.id,
    required this.name,
    this.code,
    this.kind,
    this.externalId,
    this.gatewayTaxId,
  });

  factory Procedures.fromJson(Map<String, dynamic> json) =>
      _$ProceduresFromJson(json);

  Map<String, dynamic> toJson() => _$ProceduresToJson(this);
}
