// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ciudadano.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Ciudadano _$CiudadanoFromJson(Map<String, dynamic> json) => Ciudadano(
  direccion: json['Direccion'] as String,
  email: json['Email'] as String,
  identificacion: json['Identificacion'] as String,
  primerApellido: json['PrimerApellido'] as String,
  primerNombre: json['PrimerNombre'] as String,
  segundoApellido: json['SegundoApellido'] as String,
  segundoNombre: json['SegundoNombre'] as String,
  telefono: json['Telefono'] as String,
  tipoDocumento: (json['TipoDocumento'] as num).toInt(),
);

Map<String, dynamic> _$CiudadanoToJson(Ciudadano instance) => <String, dynamic>{
  'Direccion': instance.direccion,
  'Email': instance.email,
  'Identificacion': instance.identificacion,
  'PrimerApellido': instance.primerApellido,
  'PrimerNombre': instance.primerNombre,
  'SegundoApellido': instance.segundoApellido,
  'SegundoNombre': instance.segundoNombre,
  'Telefono': instance.telefono,
  'TipoDocumento': instance.tipoDocumento,
};
