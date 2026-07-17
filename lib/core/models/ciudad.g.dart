// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ciudad.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ciudad _$CiudadFromJson(Map<String, dynamic> json) => Ciudad(
  id: pqrdCiudadIdToString(json['Id']),
  nombreCiudad: json['NombreCiudad'] as String,
);

Map<String, dynamic> _$CiudadToJson(Ciudad instance) => <String, dynamic>{
  'Id': instance.id,
  'NombreCiudad': instance.nombreCiudad,
};
