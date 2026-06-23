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

EmailDtoReservations _$EmailDtoReservationsFromJson(
  Map<String, dynamic> json,
) => EmailDtoReservations(
  id: json['Id'] as String,
  to: json['To'] as String,
  subject: json['Subject'] as String,
  idUser: json['IdUser'] as String,
  nameUser: json['NameUser'] as String,
  emailUser: json['EmailUser'] as String,
  phoneUser: json['PhoneUser'] as String,
  dateReservation: json['DateReservation'] as String?,
  type: json['Type'] as String,
  body: json['Body'] as String?,
);

Map<String, dynamic> _$EmailDtoReservationsToJson(
  EmailDtoReservations instance,
) => <String, dynamic>{
  'Id': instance.id,
  'To': instance.to,
  'Subject': instance.subject,
  'IdUser': instance.idUser,
  'NameUser': instance.nameUser,
  'EmailUser': instance.emailUser,
  'PhoneUser': instance.phoneUser,
  'DateReservation': instance.dateReservation,
  'Type': instance.type,
  'Body': instance.body,
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
