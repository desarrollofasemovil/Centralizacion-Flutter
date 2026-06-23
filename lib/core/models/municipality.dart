import 'package:json_annotation/json_annotation.dart';

part 'municipality.g.dart';

@JsonSerializable()
class Municipality {
  final String domain;
  final int id;
  final String name;
  final bool isActive;

  Municipality({
    required this.domain,
    required this.id,
    required this.name,
    required this.isActive,
  });

  factory Municipality.fromJson(Map<String, dynamic> json) =>
      _$MunicipalityFromJson(json);

  Map<String, dynamic> toJson() => _$MunicipalityToJson(this);
}
// Nota: `MunicipalitiesDTO` (id, name) vive en `municipalities_dto.dart` para
// evitar definición duplicada. El agente lo incluyó aquí porque comparte el
// archivo Kotlin `Municipality.kt`.
