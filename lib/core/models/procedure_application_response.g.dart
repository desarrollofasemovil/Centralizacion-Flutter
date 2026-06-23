// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'procedure_application_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcedureApplicationResponse _$ProcedureApplicationResponseFromJson(
  Map<String, dynamic> json,
) => ProcedureApplicationResponse(
  estado: json['Estado'] as String,
  ticket: json['Ticket'] as String,
  mensaje: json['Mensaje'] as String?,
);

Map<String, dynamic> _$ProcedureApplicationResponseToJson(
  ProcedureApplicationResponse instance,
) => <String, dynamic>{
  'Estado': instance.estado,
  'Ticket': instance.ticket,
  'Mensaje': instance.mensaje,
};
