import 'package:json_annotation/json_annotation.dart';

part 'tipo_documento.g.dart';

@JsonSerializable()
class TipoDocumento {
  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'ID')
  final int id;

  TipoDocumento({
    required this.descripcion,
    required this.id,
  });

  factory TipoDocumento.fromJson(Map<String, dynamic> json) =>
      _$TipoDocumentoFromJson(json);

  Map<String, dynamic> toJson() => _$TipoDocumentoToJson(this);
}
