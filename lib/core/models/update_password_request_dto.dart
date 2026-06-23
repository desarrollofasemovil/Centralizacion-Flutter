import 'package:json_annotation/json_annotation.dart';

part 'update_password_request_dto.g.dart';

@JsonSerializable()
class UpdatePasswordRequestDto {
  final String currentPassword;
  final String newPassword;

  const UpdatePasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  factory UpdatePasswordRequestDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatePasswordRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePasswordRequestDtoToJson(this);
}
