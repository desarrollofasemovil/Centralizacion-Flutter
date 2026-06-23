// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'people_invitated.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeopleInvitated _$PeopleInvitatedFromJson(Map<String, dynamic> json) =>
    PeopleInvitated(
      documentationDni: json['documentationDni'] as String,
      completeName: json['completeName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      email: json['email'] as String,
    );

Map<String, dynamic> _$PeopleInvitatedToJson(PeopleInvitated instance) =>
    <String, dynamic>{
      'documentationDni': instance.documentationDni,
      'completeName': instance.completeName,
      'phoneNumber': instance.phoneNumber,
      'email': instance.email,
    };
