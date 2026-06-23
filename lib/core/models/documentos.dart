import 'package:json_annotation/json_annotation.dart';

part 'documentos.g.dart';

/// Puerto de `Documentos` (pqrddto). Campos en lowerCamelCase con `@JsonKey`
/// para preservar las keys JSON originales y evitar la colisión campo/clase.
@JsonSerializable()
class Documentos {
  @JsonKey(name: 'ContentType')
  final String contentType;

  @JsonKey(name: 'Documentos')
  final String documentos;

  @JsonKey(name: 'NombreArchivo')
  final String nombreArchivo;

  const Documentos({
    required this.contentType,
    required this.documentos,
    required this.nombreArchivo,
  });

  factory Documentos.fromJson(Map<String, dynamic> json) =>
      _$DocumentosFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentosToJson(this);
}
