// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_password_request_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdatePasswordRequestDto _$UpdatePasswordRequestDtoFromJson(
  Map<String, dynamic> json,
) => UpdatePasswordRequestDto(
  currentPassword: json['currentPassword'] as String,
  newPassword: json['newPassword'] as String,
);

Map<String, dynamic> _$UpdatePasswordRequestDtoToJson(
  UpdatePasswordRequestDto instance,
) => <String, dynamic>{
  'currentPassword': instance.currentPassword,
  'newPassword': instance.newPassword,
};
