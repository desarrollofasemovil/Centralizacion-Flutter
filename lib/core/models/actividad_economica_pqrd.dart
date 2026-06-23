import 'package:json_annotation/json_annotation.dart';

part 'actividad_economica_pqrd.g.dart';

@JsonSerializable()
class ActividadEconomicaPQRD {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  ActividadEconomicaPQRD({
    required this.descripcion,
    required this.id,
  });

  factory ActividadEconomicaPQRD.fromJson(Map<String, dynamic> json) =>
      _$ActividadEconomicaPQRDFromJson(json);

  Map<String, dynamic> toJson() => _$ActividadEconomicaPQRDToJson(this);
}
