// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tipo_solicitante.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TipoSolicitante _$TipoSolicitanteFromJson(Map<String, dynamic> json) =>
    TipoSolicitante(
      descripcion: json['Descripcion'] as String,
      id: (json['ID'] as num).toInt(),
    );

Map<String, dynamic> _$TipoSolicitanteToJson(TipoSolicitante instance) =>
    <String, dynamic>{'Descripcion': instance.descripcion, 'ID': instance.id};
