// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sports_facility.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SportsFacility _$SportsFacilityFromJson(Map<String, dynamic> json) =>
    SportsFacility(
      calendaryPost: json['calendaryPost'] as String,
      get: json['get'] as String,
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      reservationPost: json['reservationPost'] as String,
      isActive: json['isActive'] as bool,
    );

Map<String, dynamic> _$SportsFacilityToJson(SportsFacility instance) =>
    <String, dynamic>{
      'calendaryPost': instance.calendaryPost,
      'get': instance.get,
      'id': instance.id,
      'name': instance.name,
      'reservationPost': instance.reservationPost,
      'isActive': instance.isActive,
    };
