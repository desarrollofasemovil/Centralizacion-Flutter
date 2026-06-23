// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateUserDTO _$CreateUserDTOFromJson(Map<String, dynamic> json) =>
    CreateUserDTO(
      id: (json['id'] as num?)?.toInt() ?? 0,
      firstName: json['firstName'] as String? ?? "",
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String? ?? "",
      secondLastName: json['secondLastName'] as String?,
      documentTypeId: (json['documentTypeId'] as num?)?.toInt() ?? 0,
      nationalId: json['nationalId'] as String? ?? "",
      email: json['email'] as String? ?? "",
      password: json['password'] as String? ?? "",
      address: json['address'] as String? ?? "",
      phoneNumber: json['phoneNumber'] as String? ?? "",
      birthDate: json['birthDate'] as String? ?? "",
      loginStatus: (json['loginStatus'] as num?)?.toInt(),
      fixedMunicipality: (json['fixedMunicipality'] as num?)?.toInt() ?? 0,
      lastMunicipality: (json['lastMunicipality'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$CreateUserDTOToJson(CreateUserDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'firstName': instance.firstName,
      'middleName': instance.middleName,
      'lastName': instance.lastName,
      'secondLastName': instance.secondLastName,
      'documentTypeId': instance.documentTypeId,
      'nationalId': instance.nationalId,
      'email': instance.email,
      'password': instance.password,
      'address': instance.address,
      'phoneNumber': instance.phoneNumber,
      'birthDate': instance.birthDate,
      'loginStatus': instance.loginStatus,
      'fixedMunicipality': instance.fixedMunicipality,
      'lastMunicipality': instance.lastMunicipality,
    };
