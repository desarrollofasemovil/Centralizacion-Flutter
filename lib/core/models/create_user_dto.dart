import 'package:json_annotation/json_annotation.dart';

part 'create_user_dto.g.dart';

@JsonSerializable()
class CreateUserDTO {
  final int id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? secondLastName;
  final int documentTypeId;
  final String nationalId;
  final String email;
  final String password;
  final String address;
  final String phoneNumber;
  final String birthDate;
  final int? loginStatus;
  final int? fixedMunicipality;
  final int? lastMunicipality;

  CreateUserDTO({
    this.id = 0,
    this.firstName = "",
    this.middleName,
    this.lastName = "",
    this.secondLastName,
    this.documentTypeId = 0,
    this.nationalId = "",
    this.email = "",
    this.password = "",
    this.address = "",
    this.phoneNumber = "",
    this.birthDate = "",
    this.loginStatus,
    this.fixedMunicipality = 0,
    this.lastMunicipality = 0,
  });

  factory CreateUserDTO.fromJson(Map<String, dynamic> json) =>
      _$CreateUserDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CreateUserDTOToJson(this);
}
