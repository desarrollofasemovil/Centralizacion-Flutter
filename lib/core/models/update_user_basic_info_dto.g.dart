// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_user_basic_info_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateUserBasicInfoDTO _$UpdateUserBasicInfoDTOFromJson(
  Map<String, dynamic> json,
) => UpdateUserBasicInfoDTO(
  firstName: json['firstName'] as String?,
  middleName: json['middleName'] as String?,
  lastName: json['lastName'] as String?,
  secondLastName: json['secondLastName'] as String?,
  address: json['address'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
);

Map<String, dynamic> _$UpdateUserBasicInfoDTOToJson(
  UpdateUserBasicInfoDTO instance,
) => <String, dynamic>{
  'firstName': instance.firstName,
  'middleName': instance.middleName,
  'lastName': instance.lastName,
  'secondLastName': instance.secondLastName,
  'address': instance.address,
  'phoneNumber': instance.phoneNumber,
};
