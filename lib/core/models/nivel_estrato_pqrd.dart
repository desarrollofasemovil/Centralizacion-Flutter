import 'package:json_annotation/json_annotation.dart';

part 'nivel_estrato_pqrd.g.dart';

@JsonSerializable()
class NivelEstratoPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  NivelEstratoPQRD({
    required this.descripcion,
    required this.id,
  });

  factory NivelEstratoPQRD.fromJson(Map<String, dynamic> json) =>
      _$NivelEstratoPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$NivelEstratoPQRDToJson(this);
}
