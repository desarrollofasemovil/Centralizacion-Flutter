import 'package:json_annotation/json_annotation.dart';

part 'asunto_interes.g.dart';

@JsonSerializable()
class AsuntoInteres {
  @JsonKey(name: 'ID')
  final int id;

  @JsonKey(name: 'Descripcion')
  final String descripcion;

  AsuntoInteres({
    required this.id,
    required this.descripcion,
  });

  factory AsuntoInteres.fromJson(Map<String, dynamic> json) =>
      _$AsuntoInteresFromJson(json);

  Map<String, dynamic> toJson() => _$AsuntoInteresToJson(this);
}
