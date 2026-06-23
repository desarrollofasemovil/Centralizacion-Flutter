// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medio_respuesta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MedioRespuesta _$MedioRespuestaFromJson(Map<String, dynamic> json) =>
    MedioRespuesta(
      descripcion: json['Descripcion'] as String,
      id: (json['ID'] as num).toInt(),
    );

Map<String, dynamic> _$MedioRespuestaToJson(MedioRespuesta instance) =>
    <String, dynamic>{'Descripcion': instance.descripcion, 'ID': instance.id};
