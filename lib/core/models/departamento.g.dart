// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'departamento.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Departamento _$DepartamentoFromJson(Map<String, dynamic> json) => Departamento(
  id: pqrdIdToString(json['Id']),
  nombreDepartamento: json['NombreDepartamento'] as String,
);

Map<String, dynamic> _$DepartamentoToJson(Departamento instance) =>
    <String, dynamic>{
      'Id': instance.id,
      'NombreDepartamento': instance.nombreDepartamento,
    };
