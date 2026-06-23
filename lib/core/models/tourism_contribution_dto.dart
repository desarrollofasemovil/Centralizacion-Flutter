import 'package:json_annotation/json_annotation.dart';

part 'tourism_contribution_dto.g.dart';

@JsonSerializable()
class TourismTaxConfigDTO {
  final TaxAgePriceRatesDTO national;
  final TaxAgePriceRatesDTO foreign;

  TourismTaxConfigDTO({
    TaxAgePriceRatesDTO? national,
    TaxAgePriceRatesDTO? foreign,
  })  : national = national ?? TaxAgePriceRatesDTO(),
        foreign = foreign ?? TaxAgePriceRatesDTO();

  factory TourismTaxConfigDTO.fromJson(Map<String, dynamic> json) =>
      _$TourismTaxConfigDTOFromJson(json);

  Map<String, dynamic> toJson() => _$TourismTaxConfigDTOToJson(this);
}

@JsonSerializable()
class TaxAgePriceRatesDTO {
  final int adult;
  final int child_7_14;
  final int teen_15_17;

  TaxAgePriceRatesDTO({
    this.adult = 58000,
    this.child_7_14 = 29000,
    this.teen_15_17 = 43000,
  });

  factory TaxAgePriceRatesDTO.fromJson(Map<String, dynamic> json) =>
      _$TaxAgePriceRatesDTOFromJson(json);

  Map<String, dynamic> toJson() => _$TaxAgePriceRatesDTOToJson(this);
}
