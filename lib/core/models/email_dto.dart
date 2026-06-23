import 'package:json_annotation/json_annotation.dart';

part 'email_dto.g.dart';

// ---------------------------------------------------------------------------
// EmailDto
// ---------------------------------------------------------------------------
@JsonSerializable()
class EmailDto {
  final String to;
  final String subject;
  final String body;

  const EmailDto({
    required this.to,
    required this.subject,
    required this.body,
  });

  factory EmailDto.fromJson(Map<String, dynamic> json) =>
      _$EmailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EmailDtoToJson(this);
}

// ---------------------------------------------------------------------------
// EmailDtoReservations
// ---------------------------------------------------------------------------
@JsonSerializable()
class EmailDtoReservations {
  @JsonKey(name: 'Id')
  final String id;

  @JsonKey(name: 'To')
  final String to;

  @JsonKey(name: 'Subject')
  final String subject;

  @JsonKey(name: 'IdUser')
  final String idUser;

  @JsonKey(name: 'NameUser')
  final String nameUser;

  @JsonKey(name: 'EmailUser')
  final String emailUser;

  @JsonKey(name: 'PhoneUser')
  final String phoneUser;

  @JsonKey(name: 'DateReservation')
  final String? dateReservation;

  @JsonKey(name: 'Type')
  final String type;

  @JsonKey(name: 'Body')
  final String? body;

  const EmailDtoReservations({
    required this.id,
    required this.to,
    required this.subject,
    required this.idUser,
    required this.nameUser,
    required this.emailUser,
    required this.phoneUser,
    this.dateReservation,
    required this.type,
    this.body,
  });

  factory EmailDtoReservations.fromJson(Map<String, dynamic> json) =>
      _$EmailDtoReservationsFromJson(json);

  Map<String, dynamic> toJson() => _$EmailDtoReservationsToJson(this);
}

// ---------------------------------------------------------------------------
// PanicEmailDto
// ---------------------------------------------------------------------------
@JsonSerializable()
class PanicEmailDto {
  @JsonKey(name: 'to')
  final String to;

  @JsonKey(name: 'subject')
  final String subject;

  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'userEmail')
  final String userEmail;

  @JsonKey(name: 'phone')
  final String phone;

  @JsonKey(name: 'locationCoordinates')
  final String locationCoordinates;

  const PanicEmailDto({
    required this.to,
    required this.subject,
    required this.name,
    required this.userEmail,
    required this.phone,
    required this.locationCoordinates,
  });

  factory PanicEmailDto.fromJson(Map<String, dynamic> json) =>
      _$PanicEmailDtoFromJson(json);

  Map<String, dynamic> toJson() => _$PanicEmailDtoToJson(this);
}
