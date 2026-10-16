// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'procedure_application_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProcedureApplicationResponse _$ProcedureApplicationResponseFromJson(
  Map<String, dynamic> json,
) => ProcedureApplicationResponse(
  estado: _estadoFromJson(json['Estado']),
  ticket: _textFromJson(json['Ticket']),
  mensaje: _optionalTextFromJson(json['Mensaje']),
);

Map<String, dynamic> _$ProcedureApplicationResponseToJson(
  ProcedureApplicationResponse instance,
) => <String, dynamic>{
  'Estado': instance.estado,
  'Ticket': instance.ticket,
  'Mensaje': instance.mensaje,
};
