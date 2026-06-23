// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document_type_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DocumentTypeDTO _$DocumentTypeDTOFromJson(Map<String, dynamic> json) =>
    DocumentTypeDTO(
      id: (json['id'] as num).toInt(),
      name: json['nameDocument'] as String,
    );

Map<String, dynamic> _$DocumentTypeDTOToJson(DocumentTypeDTO instance) =>
    <String, dynamic>{'id': instance.id, 'nameDocument': instance.name};
