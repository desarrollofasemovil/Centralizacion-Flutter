// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'atencion_preferencial.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AtencionPreferencial _$AtencionPreferencialFromJson(
  Map<String, dynamic> json,
) => AtencionPreferencial(
  descripcion: json['Descripcion'] as String,
  id: (json['ID'] as num).toInt(),
);

Map<String, dynamic> _$AtencionPreferencialToJson(
  AtencionPreferencial instance,
) => <String, dynamic>{'Descripcion': instance.descripcion, 'ID': instance.id};
