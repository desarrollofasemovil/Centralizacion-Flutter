// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pqrd_identificacion_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PqrdIdentificacionPost _$PqrdIdentificacionPostFromJson(
  Map<String, dynamic> json,
) => PqrdIdentificacionPost(
  atencionEspecial: json['AtencionEspecial'] as bool,
  ciudad: json['Ciudad'] as String,
  ciudadano: Ciudadano.fromJson(json['Ciudadano'] as Map<String, dynamic>),
  codigoEntidad: json['CodigoEntidad'] as String,
  departamento: json['Departamento'] as String,
  descripcion: json['Descripcion'] as String,
  documentos: Documentos.fromJson(json['Documentos'] as Map<String, dynamic>),
  iDActividadEconomica: (json['IDActividadEconomica'] as num).toInt(),
  iDAsunto: (json['IDAsunto'] as num).toInt(),
  iDAtencionEspecial: (json['IDAtencionEspecial'] as num).toInt(),
  iDAtencionPreferencial: (json['IDAtencionPreferencial'] as num).toInt(),
  iDClasificacion: (json['IDClasificacion'] as num).toInt(),
  iDDiscapacidad: (json['IDDiscapacidad'] as num).toInt(),
  iDEscolaridad: (json['IDEscolaridad'] as num).toInt(),
  iDGenero: (json['IDGenero'] as num).toInt(),
  iDGrupoEtnico: (json['IDGrupoEtnico'] as num).toInt(),
  iDGrupoInteres: (json['IDGrupoInteres'] as num).toInt(),
  iDMedioRespuesta: (json['IDMedioRespuesta'] as num).toInt(),
  iDNivelExtrato: (json['IDNivelExtrato'] as num).toInt(),
  iDNivelSisben: (json['IDNivelSisben'] as num).toInt(),
  iDRangoEdad: (json['IDRangoEdad'] as num).toInt(),
  iDSecretaria: (json['IDSecretaria'] as num).toInt(),
  iDTipoSolicitante: (json['IDTipoSolicitante'] as num).toInt(),
  iDVulnerabilidad: (json['IDVulnerabilidad'] as num).toInt(),
  pais: json['Pais'] as String,
  razonSocial: json['RazonSocial'] as String,
  recepcion: json['Recepcion'] as String,
);

Map<String, dynamic> _$PqrdIdentificacionPostToJson(
  PqrdIdentificacionPost instance,
) => <String, dynamic>{
  'AtencionEspecial': instance.atencionEspecial,
  'Ciudad': instance.ciudad,
  'Ciudadano': instance.ciudadano,
  'CodigoEntidad': instance.codigoEntidad,
  'Departamento': instance.departamento,
  'Descripcion': instance.descripcion,
  'Documentos': instance.documentos,
  'IDActividadEconomica': instance.iDActividadEconomica,
  'IDAsunto': instance.iDAsunto,
  'IDAtencionEspecial': instance.iDAtencionEspecial,
  'IDAtencionPreferencial': instance.iDAtencionPreferencial,
  'IDClasificacion': instance.iDClasificacion,
  'IDDiscapacidad': instance.iDDiscapacidad,
  'IDEscolaridad': instance.iDEscolaridad,
  'IDGenero': instance.iDGenero,
  'IDGrupoEtnico': instance.iDGrupoEtnico,
  'IDGrupoInteres': instance.iDGrupoInteres,
  'IDMedioRespuesta': instance.iDMedioRespuesta,
  'IDNivelExtrato': instance.iDNivelExtrato,
  'IDNivelSisben': instance.iDNivelSisben,
  'IDRangoEdad': instance.iDRangoEdad,
  'IDSecretaria': instance.iDSecretaria,
  'IDTipoSolicitante': instance.iDTipoSolicitante,
  'IDVulnerabilidad': instance.iDVulnerabilidad,
  'Pais': instance.pais,
  'RazonSocial': instance.razonSocial,
  'Recepcion': instance.recepcion,
};
