import 'package:json_annotation/json_annotation.dart';

part 'validation_response_extra_dto.g.dart';

@JsonSerializable()
class ValidationResponseExtraDto {
  final int codeStatus;
  final bool booleanStatus;
  final String sentencesError;
  final String extraData;

  const ValidationResponseExtraDto({
    this.codeStatus = 0,
    this.booleanStatus = false,
    this.sentencesError = '',
    this.extraData = '',
  });

  factory ValidationResponseExtraDto.fromJson(Map<String, dynamic> json) =>
      _$ValidationResponseExtraDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ValidationResponseExtraDtoToJson(this);
}
