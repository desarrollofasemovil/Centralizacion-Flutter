// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_response_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationResponseDTO _$ValidationResponseDTOFromJson(
  Map<String, dynamic> json,
) => ValidationResponseDTO(
  codeStatus: (json['codeStatus'] as num?)?.toInt() ?? 0,
  booleanStatus: json['booleanStatus'] as bool? ?? false,
  sentencesError: json['sentencesError'] as String? ?? '',
  result: (json['result'] as List<dynamic>?)
      ?.map((e) => MunicipalitiesDTO.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$ValidationResponseDTOToJson(
  ValidationResponseDTO instance,
) => <String, dynamic>{
  'codeStatus': instance.codeStatus,
  'booleanStatus': instance.booleanStatus,
  'sentencesError': instance.sentencesError,
  'result': instance.result,
};
