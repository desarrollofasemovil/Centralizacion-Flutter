// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'procedure_application_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcedureApplicationRequest _$ProcedureApplicationRequestFromJson(
  Map<String, dynamic> json,
) => ProcedureApplicationRequest(
  ciudadano: Ciudadano.fromJson(json['ciudadano'] as Map<String, dynamic>),
  idTramite: (json['IDTramite'] as num).toInt(),
  codigoEntidad: json['CodigoEntidad'] as String,
  descripcion: json['Descripcion'] as String,
  documentos: Documentos.fromJson(json['documentos'] as Map<String, dynamic>),
  recepcion: json['Recepcion'] as String,
);

Map<String, dynamic> _$ProcedureApplicationRequestToJson(
  ProcedureApplicationRequest instance,
) => <String, dynamic>{
  'ciudadano': instance.ciudadano,
  'IDTramite': instance.idTramite,
  'CodigoEntidad': instance.codigoEntidad,
  'Descripcion': instance.descripcion,
  'documentos': instance.documentos,
  'Recepcion': instance.recepcion,
};
