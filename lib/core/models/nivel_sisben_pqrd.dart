import 'package:json_annotation/json_annotation.dart';

part 'nivel_sisben_pqrd.g.dart';

@JsonSerializable()
class NivelSisbenPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  NivelSisbenPQRD({
    required this.descripcion,
    required this.id,
  });

  factory NivelSisbenPQRD.fromJson(Map<String, dynamic> json) =>
      _$NivelSisbenPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$NivelSisbenPQRDToJson(this);
}
