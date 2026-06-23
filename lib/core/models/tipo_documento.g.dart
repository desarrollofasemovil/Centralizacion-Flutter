// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tipo_documento.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TipoDocumento _$TipoDocumentoFromJson(Map<String, dynamic> json) =>
    TipoDocumento(
      descripcion: json['Descripcion'] as String,
      id: (json['ID'] as num).toInt(),
    );

Map<String, dynamic> _$TipoDocumentoToJson(TipoDocumento instance) =>
    <String, dynamic>{'Descripcion': instance.descripcion, 'ID': instance.id};
