// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_x.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CourseX _$CourseXFromJson(Map<String, dynamic> json) => CourseX(
  get: json['get'] as String,
  id: (json['id'] as num).toInt(),
  municipalityId: (json['municipalityId'] as num).toInt(),
  name: json['name'] as String,
  post: json['post'] as String,
  isActive: json['isActive'] as bool,
);

Map<String, dynamic> _$CourseXToJson(CourseX instance) => <String, dynamic>{
  'get': instance.get,
  'id': instance.id,
  'municipalityId': instance.municipalityId,
  'name': instance.name,
  'post': instance.post,
  'isActive': instance.isActive,
};
