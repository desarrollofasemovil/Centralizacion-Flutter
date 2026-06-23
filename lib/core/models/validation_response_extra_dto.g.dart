// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'validation_response_extra_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ValidationResponseExtraDto _$ValidationResponseExtraDtoFromJson(
  Map<String, dynamic> json,
) => ValidationResponseExtraDto(
  codeStatus: (json['codeStatus'] as num?)?.toInt() ?? 0,
  booleanStatus: json['booleanStatus'] as bool? ?? false,
  sentencesError: json['sentencesError'] as String? ?? '',
  extraData: json['extraData'] as String? ?? '',
);

Map<String, dynamic> _$ValidationResponseExtraDtoToJson(
  ValidationResponseExtraDto instance,
) => <String, dynamic>{
  'codeStatus': instance.codeStatus,
  'booleanStatus': instance.booleanStatus,
  'sentencesError': instance.sentencesError,
  'extraData': instance.extraData,
};
