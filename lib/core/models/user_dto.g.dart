// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserDTO _$UserDTOFromJson(Map<String, dynamic> json) => UserDTO(
  id: (json['id'] as num).toInt(),
  address: json['address'] as String,
  documentType: DocumentTypeDTO.fromJson(
    json['documentType'] as Map<String, dynamic>,
  ),
  documentTypeId: (json['documentTypeId'] as num).toInt(),
  email: json['email'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  loginStatus: json['loginStatus'] as bool,
  middleName: json['middleName'] as String?,
  nationalId: json['nationalId'] as String,
  password: json['password'] as String,
  phoneNumber: json['phoneNumber'] as String,
  secondLastName: json['secondLastName'] as String?,
  birthDate: json['birthDate'] as String,
  fixedMunicipality: (json['fixedMunicipality'] as num?)?.toInt(),
  lastMunicipality: (json['lastMunicipality'] as num?)?.toInt(),
);

Map<String, dynamic> _$UserDTOToJson(UserDTO instance) => <String, dynamic>{
  'id': instance.id,
  'address': instance.address,
  'documentType': instance.documentType,
  'documentTypeId': instance.documentTypeId,
  'email': instance.email,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'loginStatus': instance.loginStatus,
  'middleName': instance.middleName,
  'nationalId': instance.nationalId,
  'password': instance.password,
  'phoneNumber': instance.phoneNumber,
  'secondLastName': instance.secondLastName,
  'birthDate': instance.birthDate,
  'fixedMunicipality': instance.fixedMunicipality,
  'lastMunicipality': instance.lastMunicipality,
};
