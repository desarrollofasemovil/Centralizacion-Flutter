import 'package:json_annotation/json_annotation.dart';

part 'update_user_municipality_dto.g.dart';

@JsonSerializable()
class UpdateUserMunicipalityDTO {
  @JsonKey(name: 'municipalityId')
  final int municipalityId;

  const UpdateUserMunicipalityDTO({
    required this.municipalityId,
  });

  factory UpdateUserMunicipalityDTO.fromJson(Map<String, dynamic> json) =>
      _$UpdateUserMunicipalityDTOFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateUserMunicipalityDTOToJson(this);
}
