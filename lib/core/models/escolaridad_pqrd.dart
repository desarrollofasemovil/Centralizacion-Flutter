import 'package:json_annotation/json_annotation.dart';

part 'escolaridad_pqrd.g.dart';

@JsonSerializable()
class EscolaridadPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  EscolaridadPQRD({
    required this.descripcion,
    required this.id,
  });

  factory EscolaridadPQRD.fromJson(Map<String, dynamic> json) =>
      _$EscolaridadPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$EscolaridadPQRDToJson(this);
}
