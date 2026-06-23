// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clasificacion_solicitud.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClasificacionSolicitud _$ClasificacionSolicitudFromJson(
  Map<String, dynamic> json,
) => ClasificacionSolicitud(
  descripcion: json['Descripcion'] as String,
  id: (json['ID'] as num).toInt(),
);

Map<String, dynamic> _$ClasificacionSolicitudToJson(
  ClasificacionSolicitud instance,
) => <String, dynamic>{'Descripcion': instance.descripcion, 'ID': instance.id};
