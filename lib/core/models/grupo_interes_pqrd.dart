import 'package:json_annotation/json_annotation.dart';

part 'grupo_interes_pqrd.g.dart';

@JsonSerializable()
class GrupoInteresPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  GrupoInteresPQRD({
    required this.descripcion,
    required this.id,
  });

  factory GrupoInteresPQRD.fromJson(Map<String, dynamic> json) =>
      _$GrupoInteresPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$GrupoInteresPQRDToJson(this);
}
