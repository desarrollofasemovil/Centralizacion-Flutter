import 'package:json_annotation/json_annotation.dart';

part 'grupo_etnico_pqrd.g.dart';

@JsonSerializable()
class GrupoEtnicoPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  GrupoEtnicoPQRD({
    required this.descripcion,
    required this.id,
  });

  factory GrupoEtnicoPQRD.fromJson(Map<String, dynamic> json) =>
      _$GrupoEtnicoPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$GrupoEtnicoPQRDToJson(this);
}
