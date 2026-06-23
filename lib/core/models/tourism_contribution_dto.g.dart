// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tourism_contribution_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TourismTaxConfigDTO _$TourismTaxConfigDTOFromJson(
  Map<String, dynamic> json,
) => TourismTaxConfigDTO(
  national: json['national'] == null
      ? null
      : TaxAgePriceRatesDTO.fromJson(json['national'] as Map<String, dynamic>),
  foreign: json['foreign'] == null
      ? null
      : TaxAgePriceRatesDTO.fromJson(json['foreign'] as Map<String, dynamic>),
);

Map<String, dynamic> _$TourismTaxConfigDTOToJson(
  TourismTaxConfigDTO instance,
) => <String, dynamic>{
  'national': instance.national,
  'foreign': instance.foreign,
};

TaxAgePriceRatesDTO _$TaxAgePriceRatesDTOFromJson(Map<String, dynamic> json) =>
    TaxAgePriceRatesDTO(
      adult: (json['adult'] as num?)?.toInt() ?? 58000,
      child_7_14: (json['child_7_14'] as num?)?.toInt() ?? 29000,
      teen_15_17: (json['teen_15_17'] as num?)?.toInt() ?? 43000,
    );

Map<String, dynamic> _$TaxAgePriceRatesDTOToJson(
  TaxAgePriceRatesDTO instance,
) => <String, dynamic>{
  'adult': instance.adult,
  'child_7_14': instance.child_7_14,
  'teen_15_17': instance.teen_15_17,
};
