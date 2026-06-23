// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminders_by_user_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemindersByUserDto _$RemindersByUserDtoFromJson(Map<String, dynamic> json) =>
    RemindersByUserDto(
      id: (json['id'] as num?)?.toInt(),
      expirationDate: json['expirationDate'] as String?,
      vigenciaDate: json['vigenciaDate'] as String?,
      reminderType: json['reminderType'] as String?,
      reminderName: json['reminderName'] as String?,
      reminderTime: json['reminderTime'] as String?,
      idProcedureMunicipalityNavigation:
          json['idProcedureMunicipalityNavigation'] == null
          ? null
          : MunicipalityProcedure.fromJson(
              json['idProcedureMunicipalityNavigation'] as Map<String, dynamic>,
            ),
      idUserNavigation: json['idUserNavigation'] == null
          ? null
          : UserDtoReminders.fromJson(
              json['idUserNavigation'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$RemindersByUserDtoToJson(RemindersByUserDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'expirationDate': instance.expirationDate,
      'vigenciaDate': instance.vigenciaDate,
      'reminderType': instance.reminderType,
      'reminderName': instance.reminderName,
      'reminderTime': instance.reminderTime,
      'idProcedureMunicipalityNavigation':
          instance.idProcedureMunicipalityNavigation,
      'idUserNavigation': instance.idUserNavigation,
    };

UserDtoReminders _$UserDtoRemindersFromJson(Map<String, dynamic> json) =>
    UserDtoReminders(
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );

Map<String, dynamic> _$UserDtoRemindersToJson(UserDtoReminders instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
    };
