import 'package:json_annotation/json_annotation.dart';

part 'people_invitated.g.dart';

@JsonSerializable()
class PeopleInvitated {
  final String documentationDni;
  final String completeName;
  final String phoneNumber;
  final String email;

  const PeopleInvitated({
    required this.documentationDni,
    required this.completeName,
    required this.phoneNumber,
    required this.email,
  });

  factory PeopleInvitated.fromJson(Map<String, dynamic> json) =>
      _$PeopleInvitatedFromJson(json);

  Map<String, dynamic> toJson() => _$PeopleInvitatedToJson(this);
}
