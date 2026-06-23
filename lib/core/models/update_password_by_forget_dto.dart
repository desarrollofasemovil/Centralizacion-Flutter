import 'package:json_annotation/json_annotation.dart';

part 'update_password_by_forget_dto.g.dart';

@JsonSerializable()
class UpdatePasswordByForgetDto {
  final String newPassword;

  const UpdatePasswordByForgetDto({
    required this.newPassword,
  });

  factory UpdatePasswordByForgetDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatePasswordByForgetDtoFromJson(json);

  Map<String, dynamic> toJson() => _$UpdatePasswordByForgetDtoToJson(this);
}
