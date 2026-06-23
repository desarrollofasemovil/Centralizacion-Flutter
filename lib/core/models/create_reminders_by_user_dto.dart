import 'package:json_annotation/json_annotation.dart';

part 'create_reminders_by_user_dto.g.dart';

@JsonSerializable()
class CreateReminderDto {
  @JsonKey(name: 'ExpirationDate')
  final String? expirationDate;

  @JsonKey(name: 'VigenciaDate')
  final String? vigenciaDate;

  @JsonKey(name: 'ReminderType')
  final String? reminderType;

  @JsonKey(name: 'IdProcedureMunicipality')
  final int? idProcedureMunicipality;

  @JsonKey(name: 'IdUser')
  final int? idUser;

  @JsonKey(name: 'ReminderName')
  final String? reminderName;

  @JsonKey(name: 'ReminderTime')
  final String? reminderTime;

  const CreateReminderDto({
    this.expirationDate,
    this.vigenciaDate,
    this.reminderType,
    this.idProcedureMunicipality,
    this.idUser,
    this.reminderName,
    this.reminderTime,
  });

  factory CreateReminderDto.fromJson(Map<String, dynamic> json) =>
      _$CreateReminderDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateReminderDtoToJson(this);
}
