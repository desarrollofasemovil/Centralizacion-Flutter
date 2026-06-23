import 'package:json_annotation/json_annotation.dart';
import 'document_type_dto.dart';

part 'user_dto.g.dart';

@JsonSerializable()
class UserDTO {
  @JsonKey(name: 'id')
  final int id;
  
  @JsonKey(name: 'address')
  final String address;
  
  @JsonKey(name: 'documentType')
  final DocumentTypeDTO documentType;
  
  @JsonKey(name: 'documentTypeId')
  final int documentTypeId;
  
  @JsonKey(name: 'email')
  final String email;
  
  @JsonKey(name: 'firstName')
  final String firstName;
  
  @JsonKey(name: 'lastName')
  final String lastName;
  
  @JsonKey(name: 'loginStatus')
  final bool loginStatus;
  
  @JsonKey(name: 'middleName')
  final String? middleName;
  
  @JsonKey(name: 'nationalId')
  final String nationalId;
  
  @JsonKey(name: 'password')
  final String password;
  
  @JsonKey(name: 'phoneNumber')
  final String phoneNumber;
  
  @JsonKey(name: 'secondLastName')
  final String? secondLastName;
  
  @JsonKey(name: 'birthDate')
  final String birthDate;
  
  @JsonKey(name: 'fixedMunicipality')
  final int? fixedMunicipality;
  
  @JsonKey(name: 'lastMunicipality')
  final int? lastMunicipality;

  UserDTO({
    required this.id,
    required this.address,
    required this.documentType,
    required this.documentTypeId,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.loginStatus,
    this.middleName,
    required this.nationalId,
    required this.password,
    required this.phoneNumber,
    this.secondLastName,
    required this.birthDate,
    this.fixedMunicipality,
    this.lastMunicipality,
  });

  factory UserDTO.fromJson(Map<String, dynamic> json) => _$UserDTOFromJson(json);

  Map<String, dynamic> toJson() => _$UserDTOToJson(this);
}
