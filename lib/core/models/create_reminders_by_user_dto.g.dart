// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_reminders_by_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateReminderDto _$CreateReminderDtoFromJson(Map<String, dynamic> json) =>
    CreateReminderDto(
      expirationDate: json['ExpirationDate'] as String?,
      vigenciaDate: json['VigenciaDate'] as String?,
      reminderType: json['ReminderType'] as String?,
      idProcedureMunicipality: (json['IdProcedureMunicipality'] as num?)
          ?.toInt(),
      idUser: (json['IdUser'] as num?)?.toInt(),
      reminderName: json['ReminderName'] as String?,
      reminderTime: json['ReminderTime'] as String?,
    );

Map<String, dynamic> _$CreateReminderDtoToJson(CreateReminderDto instance) =>
    <String, dynamic>{
      'ExpirationDate': instance.expirationDate,
      'VigenciaDate': instance.vigenciaDate,
      'ReminderType': instance.reminderType,
      'IdProcedureMunicipality': instance.idProcedureMunicipality,
      'IdUser': instance.idUser,
      'ReminderName': instance.reminderName,
      'ReminderTime': instance.reminderTime,
    };
