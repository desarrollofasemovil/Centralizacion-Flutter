import 'package:json_annotation/json_annotation.dart';

part 'discapacidad_pqrd.g.dart';

@JsonSerializable()
class DiscapacidadPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  DiscapacidadPQRD({
    required this.descripcion,
    required this.id,
  });

  factory DiscapacidadPQRD.fromJson(Map<String, dynamic> json) =>
      _$DiscapacidadPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$DiscapacidadPQRDToJson(this);
}
