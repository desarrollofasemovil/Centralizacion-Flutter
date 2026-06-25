// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'news_by_municipality.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NewsByMunicipality _$NewsByMunicipalityFromJson(Map<String, dynamic> json) =>
    NewsByMunicipality(
      url: json['getUrlNew'] as String,
      idMunicipality: (json['idMunicipality'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NewsByMunicipalityToJson(NewsByMunicipality instance) =>
    <String, dynamic>{
      'getUrlNew': instance.url,
      'idMunicipality': instance.idMunicipality,
    };
