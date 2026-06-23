import 'package:json_annotation/json_annotation.dart';

import 'documentos.dart';

part 'pqrd_anonima_post.g.dart';

@JsonSerializable()
class PqrdAnonimaPost {
  @JsonKey(name: 'CodigoEntidad')
  final String codigoEntidad;

  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'Documentos')
  final Documentos documentos;

  @JsonKey(name: 'IDAsuntoInteres')
  final int idAsuntoInteres;

  @JsonKey(name: 'IDCLasificacion')
  final int idcLasificacion;

  @JsonKey(name: 'IDSecretaria')
  final int idSecretaria;

  const PqrdAnonimaPost({
    required this.codigoEntidad,
    required this.descripcion,
    required this.documentos,
    required this.idAsuntoInteres,
    required this.idcLasificacion,
    required this.idSecretaria,
  });

  factory PqrdAnonimaPost.fromJson(Map<String, dynamic> json) =>
      _$PqrdAnonimaPostFromJson(json);

  Map<String, dynamic> toJson() => _$PqrdAnonimaPostToJson(this);
}
