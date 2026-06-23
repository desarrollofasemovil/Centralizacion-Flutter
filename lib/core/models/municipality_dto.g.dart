// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'municipality_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MunicipalityDTO _$MunicipalityDTOFromJson(
  Map<String, dynamic> json,
) => MunicipalityDTO(
  courses: (json['courses'] as List<dynamic>)
      .map((e) => CourseX.fromJson(e as Map<String, dynamic>))
      .toList(),
  department: Department.fromJson(json['department'] as Map<String, dynamic>),
  domain: json['domain'] as String,
  entityCode: json['entityCode'] as String,
  id: (json['id'] as num).toInt(),
  isActive: json['isActive'] as bool,
  municipalityProcedures: (json['municipalityProcedures'] as List<dynamic>)
      .map((e) => MunicipalityProcedure.fromJson(e as Map<String, dynamic>))
      .toList(),
  municipalitySocialMedia: (json['municipalitySocialMedia'] as List<dynamic>)
      .map((e) => MunicipalitySocialMedia.fromJson(e as Map<String, dynamic>))
      .toList(),
  name: json['name'] as String,
  passwordFintech: json['passwordFintech'] as String,
  queryFields: (json['queryFields'] as List<dynamic>)
      .map((e) => QueryField.fromJson(e as Map<String, dynamic>))
      .toList(),
  sportsFacilities: (json['sportsFacilities'] as List<dynamic>)
      .map((e) => SportsFacility.fromJson(e as Map<String, dynamic>))
      .toList(),
  theme: Theme.fromJson(json['theme'] as Map<String, dynamic>),
  userFintech: json['userFintech'] as String,
  bank: BankDTO.fromJson(json['bank'] as Map<String, dynamic>),
  idShield: ShieldDTO.fromJson(json['idShield'] as Map<String, dynamic>),
  dataPrivacy: json['dataPrivacy'] as String?,
  dataProcessingPrivacy: json['dataProcessingPrivacy'] as String?,
  newsByMunicipalities: (json['newsByMunicipalities'] as List<dynamic>)
      .map((e) => NewsByMunicipality.fromJson(e as Map<String, dynamic>))
      .toList(),
  latitude: json['latitude'] as String?,
  longitude: json['longitude'] as String?,
  emailMunicipalities: json['emailMunicipalities'] as String?,
  emailPanic: json['emailPanic'] as String?,
  phone: (json['phone'] as num?)?.toInt(),
);

Map<String, dynamic> _$MunicipalityDTOToJson(MunicipalityDTO instance) =>
    <String, dynamic>{
      'courses': instance.courses,
      'department': instance.department,
      'domain': instance.domain,
      'entityCode': instance.entityCode,
      'id': instance.id,
      'isActive': instance.isActive,
      'municipalityProcedures': instance.municipalityProcedures,
      'municipalitySocialMedia': instance.municipalitySocialMedia,
      'name': instance.name,
      'passwordFintech': instance.passwordFintech,
      'queryFields': instance.queryFields,
      'sportsFacilities': instance.sportsFacilities,
      'theme': instance.theme,
      'userFintech': instance.userFintech,
      'bank': instance.bank,
      'idShield': instance.idShield,
      'dataPrivacy': instance.dataPrivacy,
      'dataProcessingPrivacy': instance.dataProcessingPrivacy,
      'newsByMunicipalities': instance.newsByMunicipalities,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'emailMunicipalities': instance.emailMunicipalities,
      'emailPanic': instance.emailPanic,
      'phone': instance.phone,
    };
