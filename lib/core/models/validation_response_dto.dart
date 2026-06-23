import 'package:json_annotation/json_annotation.dart';
import 'municipalities_dto.dart';

part 'validation_response_dto.g.dart';

@JsonSerializable()
class ValidationResponseDTO {
  @JsonKey(name: 'codeStatus')
  final int codeStatus;

  @JsonKey(name: 'booleanStatus')
  final bool booleanStatus;

  @JsonKey(name: 'sentencesError')
  final String sentencesError;

  @JsonKey(name: 'result')
  final List<MunicipalitiesDTO>? result;

  ValidationResponseDTO({
    this.codeStatus = 0,
    this.booleanStatus = false,
    this.sentencesError = '',
    this.result,
  });

  factory ValidationResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$ValidationResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationResponseDTOToJson(this);
}
