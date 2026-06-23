import 'package:json_annotation/json_annotation.dart';

part 'vulnerabilidad_pqrd.g.dart';

@JsonSerializable()
class VulnerabilidadPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  VulnerabilidadPQRD({
    required this.descripcion,
    required this.id,
  });

  factory VulnerabilidadPQRD.fromJson(Map<String, dynamic> json) =>
      _$VulnerabilidadPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$VulnerabilidadPQRDToJson(this);
}
