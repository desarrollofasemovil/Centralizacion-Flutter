import 'package:json_annotation/json_annotation.dart';

part 'tipo_solicitante.g.dart';

/// Puerto de `TipoSolicitante` (pqrddto).
@JsonSerializable()
class TipoSolicitante {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  const TipoSolicitante({
    required this.descripcion,
    required this.id,
  });

  factory TipoSolicitante.fromJson(Map<String, dynamic> json) =>
      _$TipoSolicitanteFromJson(json);

  Map<String, dynamic> toJson() => _$TipoSolicitanteToJson(this);
}
