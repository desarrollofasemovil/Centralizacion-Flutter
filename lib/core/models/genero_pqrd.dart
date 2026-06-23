import 'package:json_annotation/json_annotation.dart';

part 'genero_pqrd.g.dart';

@JsonSerializable()
class GeneroPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  GeneroPQRD({
    required this.descripcion,
    required this.id,
  });

  factory GeneroPQRD.fromJson(Map<String, dynamic> json) =>
      _$GeneroPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$GeneroPQRDToJson(this);
}
