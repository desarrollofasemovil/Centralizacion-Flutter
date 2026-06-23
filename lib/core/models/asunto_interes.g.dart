// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asunto_interes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AsuntoInteres _$AsuntoInteresFromJson(Map<String, dynamic> json) =>
    AsuntoInteres(
      id: (json['ID'] as num).toInt(),
      descripcion: json['Descripcion'] as String,
    );

Map<String, dynamic> _$AsuntoInteresToJson(AsuntoInteres instance) =>
    <String, dynamic>{'ID': instance.id, 'Descripcion': instance.descripcion};
