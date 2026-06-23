// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'query_field.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QueryField _$QueryFieldFromJson(Map<String, dynamic> json) => QueryField(
  id: (json['id'] as num).toInt(),
  queryFieldType: json['queryFieldType'] as String,
  fieldName: json['fieldName'] as String,
  municipality: json['municipality'] == null
      ? null
      : Municipality.fromJson(json['municipality'] as Map<String, dynamic>),
);

Map<String, dynamic> _$QueryFieldToJson(QueryField instance) =>
    <String, dynamic>{
      'id': instance.id,
      'queryFieldType': instance.queryFieldType,
      'fieldName': instance.fieldName,
      'municipality': instance.municipality,
    };
