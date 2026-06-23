// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pqrd_anonima_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PqrdAnonimaPost _$PqrdAnonimaPostFromJson(Map<String, dynamic> json) =>
    PqrdAnonimaPost(
      codigoEntidad: json['CodigoEntidad'] as String,
      descripcion: json['Descripcion'] as String,
      documentos: Documentos.fromJson(
        json['Documentos'] as Map<String, dynamic>,
      ),
      idAsuntoInteres: (json['IDAsuntoInteres'] as num).toInt(),
      idcLasificacion: (json['IDCLasificacion'] as num).toInt(),
      idSecretaria: (json['IDSecretaria'] as num).toInt(),
    );

Map<String, dynamic> _$PqrdAnonimaPostToJson(PqrdAnonimaPost instance) =>
    <String, dynamic>{
      'CodigoEntidad': instance.codigoEntidad,
      'Descripcion': instance.descripcion,
      'Documentos': instance.documentos,
      'IDAsuntoInteres': instance.idAsuntoInteres,
      'IDCLasificacion': instance.idcLasificacion,
      'IDSecretaria': instance.idSecretaria,
    };
