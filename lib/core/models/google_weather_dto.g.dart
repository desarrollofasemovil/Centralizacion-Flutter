// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_weather_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForecastResponse _$ForecastResponseFromJson(Map<String, dynamic> json) =>
    ForecastResponse(
      forecastDays: (json['forecastDays'] as List<dynamic>)
          .map((e) => DailyForecastDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ForecastResponseToJson(ForecastResponse instance) =>
    <String, dynamic>{'forecastDays': instance.forecastDays};

DailyForecastDTO _$DailyForecastDTOFromJson(Map<String, dynamic> json) =>
    DailyForecastDTO(
      displayDate: DateDTO.fromJson(
        json['displayDate'] as Map<String, dynamic>,
      ),
      maxTemperature: TemperatureDTO.fromJson(
        json['maxTemperature'] as Map<String, dynamic>,
      ),
      minTemperature: TemperatureDTO.fromJson(
        json['minTemperature'] as Map<String, dynamic>,
      ),
      daytimeForecast: ForecastPeriodDTO.fromJson(
        json['daytimeForecast'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$DailyForecastDTOToJson(DailyForecastDTO instance) =>
    <String, dynamic>{
      'displayDate': instance.displayDate,
      'maxTemperature': instance.maxTemperature,
      'minTemperature': instance.minTemperature,
      'daytimeForecast': instance.daytimeForecast,
    };

DateDTO _$DateDTOFromJson(Map<String, dynamic> json) => DateDTO(
  year: (json['year'] as num).toInt(),
  month: (json['month'] as num).toInt(),
  day: (json['day'] as num).toInt(),
);

Map<String, dynamic> _$DateDTOToJson(DateDTO instance) => <String, dynamic>{
  'year': instance.year,
  'month': instance.month,
  'day': instance.day,
};

TemperatureDTO _$TemperatureDTOFromJson(Map<String, dynamic> json) =>
    TemperatureDTO(degrees: (json['degrees'] as num).toDouble());

Map<String, dynamic> _$TemperatureDTOToJson(TemperatureDTO instance) =>
    <String, dynamic>{'degrees': instance.degrees};

ForecastPeriodDTO _$ForecastPeriodDTOFromJson(Map<String, dynamic> json) =>
    ForecastPeriodDTO(
      weatherCondition: WeatherConditionDTO.fromJson(
        json['weatherCondition'] as Map<String, dynamic>,
      ),
      precipitation: PrecipitationDTO.fromJson(
        json['precipitation'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$ForecastPeriodDTOToJson(ForecastPeriodDTO instance) =>
    <String, dynamic>{
      'weatherCondition': instance.weatherCondition,
      'precipitation': instance.precipitation,
    };

WeatherConditionDTO _$WeatherConditionDTOFromJson(Map<String, dynamic> json) =>
    WeatherConditionDTO(iconBaseUri: json['iconBaseUri'] as String);

Map<String, dynamic> _$WeatherConditionDTOToJson(
  WeatherConditionDTO instance,
) => <String, dynamic>{'iconBaseUri': instance.iconBaseUri};

PrecipitationDTO _$PrecipitationDTOFromJson(Map<String, dynamic> json) =>
    PrecipitationDTO(
      probability: ProbabilityDTO.fromJson(
        json['probability'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$PrecipitationDTOToJson(PrecipitationDTO instance) =>
    <String, dynamic>{'probability': instance.probability};

ProbabilityDTO _$ProbabilityDTOFromJson(Map<String, dynamic> json) =>
    ProbabilityDTO(percent: (json['percent'] as num).toInt());

Map<String, dynamic> _$ProbabilityDTOToJson(ProbabilityDTO instance) =>
    <String, dynamic>{'percent': instance.percent};

CurrentConditionsResponse _$CurrentConditionsResponseFromJson(
  Map<String, dynamic> json,
) => CurrentConditionsResponse(
  temperature: TemperatureDTO.fromJson(
    json['temperature'] as Map<String, dynamic>,
  ),
  weatherCondition: WeatherConditionDTO.fromJson(
    json['weatherCondition'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$CurrentConditionsResponseToJson(
  CurrentConditionsResponse instance,
) => <String, dynamic>{
  'temperature': instance.temperature,
  'weatherCondition': instance.weatherCondition,
};
