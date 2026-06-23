// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'response_pqrd.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ResponsePQRD _$ResponsePQRDFromJson(Map<String, dynamic> json) => ResponsePQRD(
  estado: json['Estado'] as bool,
  ticket: json['Ticket'] as String,
);

Map<String, dynamic> _$ResponsePQRDToJson(ResponsePQRD instance) =>
    <String, dynamic>{'Estado': instance.estado, 'Ticket': instance.ticket};
