// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'social_media_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SocialMediaType _$SocialMediaTypeFromJson(Map<String, dynamic> json) =>
    SocialMediaType(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
    );

Map<String, dynamic> _$SocialMediaTypeToJson(SocialMediaType instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
