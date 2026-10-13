// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

EmailDto _$EmailDtoFromJson(Map<String, dynamic> json) => EmailDto(
  to: json['to'] as String,
  subject: json['subject'] as String,
  body: json['body'] as String,
);

Map<String, dynamic> _$EmailDtoToJson(EmailDto instance) => <String, dynamic>{
  'to': instance.to,
  'subject': instance.subject,
  'body': instance.body,
};

PanicEmailDto _$PanicEmailDtoFromJson(Map<String, dynamic> json) =>
    PanicEmailDto(
      to: json['to'] as String,
      subject: json['subject'] as String,
      name: json['name'] as String,
      userEmail: json['userEmail'] as String,
      phone: json['phone'] as String,
      locationCoordinates: json['locationCoordinates'] as String,
    );

Map<String, dynamic> _$PanicEmailDtoToJson(PanicEmailDto instance) =>
    <String, dynamic>{
      'to': instance.to,
      'subject': instance.subject,
      'name': instance.name,
      'userEmail': instance.userEmail,
      'phone': instance.phone,
      'locationCoordinates': instance.locationCoordinates,
    };
