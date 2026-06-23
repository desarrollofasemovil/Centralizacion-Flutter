import 'package:json_annotation/json_annotation.dart';

part 'google_weather_dto.g.dart';

// ---------------------------------------------------------------------------
// ForecastResponse
// ---------------------------------------------------------------------------
@JsonSerializable()
class ForecastResponse {
  final List<DailyForecastDTO> forecastDays;

  const ForecastResponse({
    required this.forecastDays,
  });

  factory ForecastResponse.fromJson(Map<String, dynamic> json) =>
      _$ForecastResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ForecastResponseToJson(this);
}

// ---------------------------------------------------------------------------
// DailyForecastDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class DailyForecastDTO {
  final DateDTO displayDate;
  final TemperatureDTO maxTemperature;
  final TemperatureDTO minTemperature;
  final ForecastPeriodDTO daytimeForecast;

  const DailyForecastDTO({
    required this.displayDate,
    required this.maxTemperature,
    required this.minTemperature,
    required this.daytimeForecast,
  });

  factory DailyForecastDTO.fromJson(Map<String, dynamic> json) =>
      _$DailyForecastDTOFromJson(json);

  Map<String, dynamic> toJson() => _$DailyForecastDTOToJson(this);
}

// ---------------------------------------------------------------------------
// DateDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class DateDTO {
  final int year;
  final int month;
  final int day;

  const DateDTO({
    required this.year,
    required this.month,
    required this.day,
  });

  factory DateDTO.fromJson(Map<String, dynamic> json) =>
      _$DateDTOFromJson(json);

  Map<String, dynamic> toJson() => _$DateDTOToJson(this);
}

// ---------------------------------------------------------------------------
// TemperatureDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class TemperatureDTO {
  final double degrees;

  const TemperatureDTO({
    required this.degrees,
  });

  factory TemperatureDTO.fromJson(Map<String, dynamic> json) =>
      _$TemperatureDTOFromJson(json);

  Map<String, dynamic> toJson() => _$TemperatureDTOToJson(this);
}

// ---------------------------------------------------------------------------
// ForecastPeriodDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class ForecastPeriodDTO {
  final WeatherConditionDTO weatherCondition;
  final PrecipitationDTO precipitation;

  const ForecastPeriodDTO({
    required this.weatherCondition,
    required this.precipitation,
  });

  factory ForecastPeriodDTO.fromJson(Map<String, dynamic> json) =>
      _$ForecastPeriodDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ForecastPeriodDTOToJson(this);
}

// ---------------------------------------------------------------------------
// WeatherConditionDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class WeatherConditionDTO {
  final String iconBaseUri;

  const WeatherConditionDTO({
    required this.iconBaseUri,
  });

  factory WeatherConditionDTO.fromJson(Map<String, dynamic> json) =>
      _$WeatherConditionDTOFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherConditionDTOToJson(this);
}

// ---------------------------------------------------------------------------
// PrecipitationDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class PrecipitationDTO {
  final ProbabilityDTO probability;

  const PrecipitationDTO({
    required this.probability,
  });

  factory PrecipitationDTO.fromJson(Map<String, dynamic> json) =>
      _$PrecipitationDTOFromJson(json);

  Map<String, dynamic> toJson() => _$PrecipitationDTOToJson(this);
}

// ---------------------------------------------------------------------------
// ProbabilityDTO
// ---------------------------------------------------------------------------
@JsonSerializable()
class ProbabilityDTO {
  final int percent;

  const ProbabilityDTO({
    required this.percent,
  });

  factory ProbabilityDTO.fromJson(Map<String, dynamic> json) =>
      _$ProbabilityDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ProbabilityDTOToJson(this);
}

// ---------------------------------------------------------------------------
// CurrentConditionsResponse
// ---------------------------------------------------------------------------
@JsonSerializable()
class CurrentConditionsResponse {
  final TemperatureDTO temperature;
  final WeatherConditionDTO weatherCondition;

  const CurrentConditionsResponse({
    required this.temperature,
    required this.weatherCondition,
  });

  factory CurrentConditionsResponse.fromJson(Map<String, dynamic> json) =>
      _$CurrentConditionsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CurrentConditionsResponseToJson(this);
}
