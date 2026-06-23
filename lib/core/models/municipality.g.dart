// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'municipality.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Municipality _$MunicipalityFromJson(Map<String, dynamic> json) => Municipality(
  domain: json['domain'] as String,
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$MunicipalityToJson(Municipality instance) =>
    <String, dynamic>{
      'domain': instance.domain,
      'id': instance.id,
      'name': instance.name,
      'isActive': instance.isActive,
    };
