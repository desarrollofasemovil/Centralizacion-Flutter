import 'package:json_annotation/json_annotation.dart';

part 'update_user_basic_info_dto.g.dart';

@JsonSerializable()
class UpdateUserBasicInfoDTO {
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? secondLastName;
  final String? address;
  final String? phoneNumber;

  const UpdateUserBasicInfoDTO({
    this.firstName,
    this.middleName,
    this.lastName,
    this.secondLastName,
    this.address,
    this.phoneNumber,
  });

  factory UpdateUserBasicInfoDTO.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserBasicInfoDTOFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserBasicInfoDTOToJson(this);
}
