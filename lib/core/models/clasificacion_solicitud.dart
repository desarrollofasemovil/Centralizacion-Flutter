import 'package:json_annotation/json_annotation.dart';

part 'clasificacion_solicitud.g.dart';

@JsonSerializable()
class ClasificacionSolicitud {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  ClasificacionSolicitud({
    required this.descripcion,
    required this.id,
  });

  factory ClasificacionSolicitud.fromJson(Map<String, dynamic> json) =>
      _$ClasificacionSolicitudFromJson(json);

  Map<String, dynamic> toJson() => _$ClasificacionSolicitudToJson(this);
}
