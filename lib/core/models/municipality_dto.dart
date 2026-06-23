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

@JsonSerializable()
class MunicipalityDTO {
  final List<CourseX> courses;
  final Department department;
  final String domain;
  final String entityCode;
  final int id;
  final bool isActive;
  final List<MunicipalityProcedure> municipalityProcedures;
  final List<MunicipalitySocialMedia> municipalitySocialMedia;
  final String name;
  final String passwordFintech;
  final List<QueryField> queryFields;
  final List<SportsFacility> sportsFacilities;
  final Theme theme;
  final String userFintech;
  final BankDTO bank;
  final ShieldDTO idShield;
  @JsonKey(name: 'dataPrivacy')
  final String? dataPrivacy;
  @JsonKey(name: 'dataProcessingPrivacy')
  final String? dataProcessingPrivacy;
  @JsonKey(name: 'newsByMunicipalities')
  final List<NewsByMunicipality> newsByMunicipalities;
  @JsonKey(name: 'latitude')
  final String? latitude;
  @JsonKey(name: 'longitude')
  final String? longitude;
  @JsonKey(name: 'emailMunicipalities')
  final String? emailMunicipalities;
  @JsonKey(name: 'emailPanic')
  final String? emailPanic;
  @JsonKey(name: 'phone')
  final int? phone;

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
