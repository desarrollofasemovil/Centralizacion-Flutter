import 'package:json_annotation/json_annotation.dart';

part 'ciudad.g.dart';

@JsonSerializable()
class Ciudad {
  @JsonKey(name: 'Id')
  final String id;

  @JsonKey(name: 'NombreCiudad')
  final String nombreCiudad;

  Ciudad({
    required this.id,
    required this.nombreCiudad,
  });

  factory Ciudad.fromJson(Map<String, dynamic> json) => _$CiudadFromJson(json);

  Map<String, dynamic> toJson() => _$CiudadToJson(this);
}
