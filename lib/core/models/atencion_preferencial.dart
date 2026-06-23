import 'package:json_annotation/json_annotation.dart';

part 'atencion_preferencial.g.dart';

@JsonSerializable()
class AtencionPreferencial {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  AtencionPreferencial({
    required this.descripcion,
    required this.id,
  });

  factory AtencionPreferencial.fromJson(Map<String, dynamic> json) =>
      _$AtencionPreferencialFromJson(json);

  Map<String, dynamic> toJson() => _$AtencionPreferencialToJson(this);
}
