// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'municipality_procedure.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MunicipalityProcedure _$MunicipalityProcedureFromJson(
  Map<String, dynamic> json,
) => MunicipalityProcedure(
  id: (json['id'] as num).toInt(),
  integrationType: json['integrationType'] as String,
  isActive: json['isActive'] as bool,
  municipality: Municipality.fromJson(
    json['municipality'] as Map<String, dynamic>,
  ),
  procedures: Procedures.fromJson(json['procedures'] as Map<String, dynamic>),
);

Map<String, dynamic> _$MunicipalityProcedureToJson(
  MunicipalityProcedure instance,
) => <String, dynamic>{
  'id': instance.id,
  'integrationType': instance.integrationType,
  'isActive': instance.isActive,
  'municipality': instance.municipality,
  'procedures': instance.procedures,
};
