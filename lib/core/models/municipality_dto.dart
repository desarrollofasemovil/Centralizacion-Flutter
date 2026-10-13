import 'package:json_annotation/json_annotation.dart';
import 'course_x.dart';
import 'department.dart';
import 'municipality_procedure.dart';
import 'municipality_social_media.dart';
import 'query_field.dart';
import 'sports_facility.dart';
import 'theme.dart';
import 'bank_dto.dart';
import 'shield_dto.dart';
import 'news_by_municipality.dart';

part 'municipality_dto.g.dart';

// La API declara casi todo nullable (`GetMunicipalitysDto.cs`) y el wizard del
// dashboard ya crea municipios con campos vacíos. Un objeto anidado `null` se lee
// como uno "vacío" (strings `''`, listas `[]`): así el municipio abre con los
// fallbacks de siempre (colores grises de `parseColor`, ícono en vez de escudo)
// en vez de que `GetInfoBy{id}` lance. Con datos completos nada cambia.
Department _departmentOrEmpty(Map<String, dynamic>? json) =>
    Department.fromJson(json ?? const <String, dynamic>{});
Theme _themeOrEmpty(Map<String, dynamic>? json) =>
    Theme.fromJson(json ?? const <String, dynamic>{});
BankDTO _bankOrEmpty(Map<String, dynamic>? json) =>
    BankDTO.fromJson(json ?? const <String, dynamic>{});
ShieldDTO _shieldOrEmpty(Map<String, dynamic>? json) =>
    ShieldDTO.fromJson(json ?? const <String, dynamic>{});
String? _phoneAsString(Object? value) => value?.toString();

@JsonSerializable()
class MunicipalityDTO {
  @JsonKey(defaultValue: <CourseX>[])
  final List<CourseX> courses;
  @JsonKey(fromJson: _departmentOrEmpty)
  final Department department;
  @JsonKey(defaultValue: '')
  final String domain;
  @JsonKey(defaultValue: '')
  final String entityCode;
  final int id;
  @JsonKey(defaultValue: false)
  final bool isActive;
  @JsonKey(defaultValue: <MunicipalityProcedure>[])
  final List<MunicipalityProcedure> municipalityProcedures;
  @JsonKey(defaultValue: <MunicipalitySocialMedia>[])
  final List<MunicipalitySocialMedia> municipalitySocialMedia;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: '')
  final String passwordFintech;
  @JsonKey(defaultValue: <QueryField>[])
  final List<QueryField> queryFields;
  @JsonKey(defaultValue: <SportsFacility>[])
  final List<SportsFacility> sportsFacilities;
  @JsonKey(fromJson: _themeOrEmpty)
  final Theme theme;
  @JsonKey(defaultValue: '')
  final String userFintech;
  @JsonKey(fromJson: _bankOrEmpty)
  final BankDTO bank;
  @JsonKey(fromJson: _shieldOrEmpty)
  final ShieldDTO idShield;
  @JsonKey(name: 'dataPrivacy')
  final String? dataPrivacy;
  @JsonKey(name: 'dataProcessingPrivacy')
  final String? dataProcessingPrivacy;
  @JsonKey(name: 'newsByMunicipalities', defaultValue: <NewsByMunicipality>[])
  final List<NewsByMunicipality> newsByMunicipalities;
  @JsonKey(name: 'latitude')
  final String? latitude;
  @JsonKey(name: 'longitude')
  final String? longitude;
  @JsonKey(name: 'emailMunicipalities')
  final String? emailMunicipalities;
  @JsonKey(name: 'emailPanic')
  final String? emailPanic;
  /// `string?` en la API (`GetMunicipalitysDto.Phone`, string desde 2025-11).
  /// Se acepta también un número por si algún entorno aún lo manda así.
  @JsonKey(name: 'phone', fromJson: _phoneAsString)
  final String? phone;

  MunicipalityDTO({
    required this.courses,
    required this.department,
    required this.domain,
    required this.entityCode,
    required this.id,
    required this.isActive,
    required this.municipalityProcedures,
    required this.municipalitySocialMedia,
    required this.name,
    required this.passwordFintech,
    required this.queryFields,
    required this.sportsFacilities,
    required this.theme,
    required this.userFintech,
    required this.bank,
    required this.idShield,
    this.dataPrivacy,
    this.dataProcessingPrivacy,
    required this.newsByMunicipalities,
    this.latitude,
    this.longitude,
    this.emailMunicipalities,
    this.emailPanic,
    this.phone,
  });

  factory MunicipalityDTO.fromJson(Map<String, dynamic> json) =>
      _$MunicipalityDTOFromJson(json);

  Map<String, dynamic> toJson() => _$MunicipalityDTOToJson(this);
}
