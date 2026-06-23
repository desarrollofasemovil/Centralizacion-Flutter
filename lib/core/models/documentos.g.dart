// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documentos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Documentos _$DocumentosFromJson(Map<String, dynamic> json) => Documentos(
  contentType: json['ContentType'] as String,
  documentos: json['Documentos'] as String,
  nombreArchivo: json['NombreArchivo'] as String,
);

Map<String, dynamic> _$DocumentosToJson(Documentos instance) =>
    <String, dynamic>{
      'ContentType': instance.contentType,
      'Documentos': instance.documentos,
      'NombreArchivo': instance.nombreArchivo,
    };
