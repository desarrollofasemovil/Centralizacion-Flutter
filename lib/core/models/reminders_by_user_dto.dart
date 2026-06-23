import 'package:json_annotation/json_annotation.dart';

import 'municipality_procedure.dart';

part 'reminders_by_user_dto.g.dart';

@JsonSerializable()
class RemindersByUserDto {
  final int? id;
  final String? expirationDate;
  final String? vigenciaDate;
  final String? reminderType;

  @JsonKey(name: 'reminderName')
  final String? reminderName;

  @JsonKey(name: 'reminderTime')
  final String? reminderTime;

  final MunicipalityProcedure? idProcedureMunicipalityNavigation;
  final UserDtoReminders? idUserNavigation;

  const RemindersByUserDto({
    this.id,
    this.expirationDate,
    this.vigenciaDate,
    this.reminderType,
    this.reminderName,
    this.reminderTime,
    this.idProcedureMunicipalityNavigation,
    this.idUserNavigation,
  });

  factory RemindersByUserDto.fromJson(Map<String, dynamic> json) =>
      _$RemindersByUserDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RemindersByUserDtoToJson(this);
}

@JsonSerializable()
class UserDtoReminders {
  final String? firstName;
  final String? lastName;

  const UserDtoReminders({
    this.firstName,
    this.lastName,
  });

  factory UserDtoReminders.fromJson(Map<String, dynamic> json) =>
      _$UserDtoRemindersFromJson(json);

  Map<String, dynamic> toJson() => _$UserDtoRemindersToJson(this);
}
