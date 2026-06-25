// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'municipality_social_media.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MunicipalitySocialMedia _$MunicipalitySocialMediaFromJson(
  Map<String, dynamic> json,
) => MunicipalitySocialMedia(
  id: (json['id'] as num).toInt(),
  isActive: json['isActive'] as bool,
  municipality: json['municipality'] == null
      ? null
      : Municipality.fromJson(json['municipality'] as Map<String, dynamic>),
  socialMediaType: SocialMediaType.fromJson(
    json['socialMediaType'] as Map<String, dynamic>,
  ),
  url: json['url'] as String,
);

Map<String, dynamic> _$MunicipalitySocialMediaToJson(
  MunicipalitySocialMedia instance,
) => <String, dynamic>{
  'id': instance.id,
  'isActive': instance.isActive,
  'municipality': instance.municipality,
  'socialMediaType': instance.socialMediaType,
  'url': instance.url,
};
