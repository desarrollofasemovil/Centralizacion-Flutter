import 'package:json_annotation/json_annotation.dart';
import 'municipality.dart';
import 'procedures.dart';

part 'municipality_procedure.g.dart';

/// `procedures` nulo se lee como un trámite vacío (id 0), que el mapeo de
/// trámites no reconoce y descarta, en vez de romper `GetInfoBy{id}`.
Procedures _proceduresOrEmpty(Map<String, dynamic>? json) =>
    Procedures.fromJson(json ?? const <String, dynamic>{});

@JsonSerializable()
class MunicipalityProcedure {
  final int id;
  @JsonKey(defaultValue: '')
  final String integrationType;
  @JsonKey(defaultValue: false)
  final bool isActive;
  final Municipality? municipality;
  @JsonKey(fromJson: _proceduresOrEmpty)
  final Procedures procedures;

  MunicipalityProcedure({
    required this.id,
    required this.integrationType,
    required this.isActive,
    this.municipality,
    required this.procedures,
  });

  factory MunicipalityProcedure.fromJson(Map<String, dynamic> json) =>
      _$MunicipalityProcedureFromJson(json);

  Map<String, dynamic> toJson() => _$MunicipalityProcedureToJson(this);
}
