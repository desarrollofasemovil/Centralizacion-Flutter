// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Theme _$ThemeFromJson(Map<String, dynamic> json) => Theme(
  backGroundColor: json['backGroundColor'] as String,
  onPrimaryColorDark: json['onPrimaryColorDark'] as String,
  onPrimaryColorLight: json['onPrimaryColorLight'] as String,
  primaryColor: json['primaryColor'] as String,
  secondaryColor: json['secondaryColor'] as String,
  secondaryColorBlack: json['secondaryColorBlack'] as String,
);

Map<String, dynamic> _$ThemeToJson(Theme instance) => <String, dynamic>{
  'backGroundColor': instance.backGroundColor,
  'onPrimaryColorDark': instance.onPrimaryColorDark,
  'onPrimaryColorLight': instance.onPrimaryColorLight,
  'primaryColor': instance.primaryColor,
  'secondaryColor': instance.secondaryColor,
  'secondaryColorBlack': instance.secondaryColorBlack,
};
