// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'secretaria.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Secretaria _$SecretariaFromJson(Map<String, dynamic> json) => Secretaria(
  idSecretaria: (json['IDSecretaria'] as num).toInt(),
  direccion: json['Direccion'],
  email: json['Email'],
  estado: json['Estado'],
  horario: json['Horario'],
  secretaria: json['Secretaria'] as String,
  telefono: json['Telefono'],
);

Map<String, dynamic> _$SecretariaToJson(Secretaria instance) =>
    <String, dynamic>{
      'IDSecretaria': instance.idSecretaria,
      'Direccion': instance.direccion,
      'Email': instance.email,
      'Estado': instance.estado,
      'Horario': instance.horario,
      'Secretaria': instance.secretaria,
      'Telefono': instance.telefono,
    };
