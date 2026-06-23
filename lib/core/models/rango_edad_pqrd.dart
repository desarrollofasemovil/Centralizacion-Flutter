import 'package:json_annotation/json_annotation.dart';

part 'rango_edad_pqrd.g.dart';

@JsonSerializable()
class RangoEdadPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  RangoEdadPQRD({
    required this.descripcion,
    required this.id,
  });

  factory RangoEdadPQRD.fromJson(Map<String, dynamic> json) =>
      _$RangoEdadPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$RangoEdadPQRDToJson(this);
}
