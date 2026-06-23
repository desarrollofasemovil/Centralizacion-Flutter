// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'municipalities_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MunicipalitiesDTO _$MunicipalitiesDTOFromJson(Map<String, dynamic> json) =>
    MunicipalitiesDTO(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$MunicipalitiesDTOToJson(MunicipalitiesDTO instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
