import 'package:json_annotation/json_annotation.dart';

part 'medio_respuesta.g.dart';

@JsonSerializable()
class MedioRespuesta {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  MedioRespuesta({
    required this.descripcion,
    required this.id,
  });

  factory MedioRespuesta.fromJson(Map<String, dynamic> json) =>
      _$MedioRespuestaFromJson(json);

  Map<String, dynamic> toJson() => _$MedioRespuestaToJson(this);
}
