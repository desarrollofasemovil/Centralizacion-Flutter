import 'package:json_annotation/json_annotation.dart';
import 'municipality.dart';
import 'procedures.dart';

part 'municipality_procedure.g.dart';

@JsonSerializable()
class MunicipalityProcedure {
  final int id;
  final String integrationType;
  final bool isActive;
  final Municipality municipality;
  final Procedures procedures;

  MunicipalityProcedure({
    required this.id,
    required this.integrationType,
    required this.isActive,
    required this.municipality,
    required this.procedures,
  });

  factory MunicipalityProcedure.fromJson(Map<String, dynamic> json) =>
      _$MunicipalityProcedureFromJson(json);

  Map<String, dynamic> toJson() => _$MunicipalityProcedureToJson(this);
}
