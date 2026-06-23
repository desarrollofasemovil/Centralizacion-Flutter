import 'package:json_annotation/json_annotation.dart';

import 'ciudadano.dart';
import 'documentos.dart';

part 'pqrd_identificacion_post.g.dart';

@JsonSerializable()
class PqrdIdentificacionPost {
  @JsonKey(name: 'AtencionEspecial')
  final bool atencionEspecial;

  @JsonKey(name: 'Ciudad')
  final String ciudad;

  @JsonKey(name: 'Ciudadano')
  final Ciudadano ciudadano;

  @JsonKey(name: 'CodigoEntidad')
  final String codigoEntidad;

  @JsonKey(name: 'Departamento')
  final String departamento;

  @JsonKey(name: 'Descripcion')
  final String descripcion;

  @JsonKey(name: 'Documentos')
  final Documentos documentos;

  @JsonKey(name: 'IDActividadEconomica')
  final int iDActividadEconomica;

  @JsonKey(name: 'IDAsunto')
  final int iDAsunto;

  @JsonKey(name: 'IDAtencionEspecial')
  final int iDAtencionEspecial;

  @JsonKey(name: 'IDAtencionPreferencial')
  final int iDAtencionPreferencial;

  @JsonKey(name: 'IDClasificacion')
  final int iDClasificacion;

  @JsonKey(name: 'IDDiscapacidad')
  final int iDDiscapacidad;

  @JsonKey(name: 'IDEscolaridad')
  final int iDEscolaridad;

  @JsonKey(name: 'IDGenero')
  final int iDGenero;

  @JsonKey(name: 'IDGrupoEtnico')
  final int iDGrupoEtnico;

  @JsonKey(name: 'IDGrupoInteres')
  final int iDGrupoInteres;

  @JsonKey(name: 'IDMedioRespuesta')
  final int iDMedioRespuesta;

  @JsonKey(name: 'IDNivelExtrato')
  final int iDNivelExtrato;

  @JsonKey(name: 'IDNivelSisben')
  final int iDNivelSisben;

  @JsonKey(name: 'IDRangoEdad')
  final int iDRangoEdad;

  @JsonKey(name: 'IDSecretaria')
  final int iDSecretaria;

  @JsonKey(name: 'IDTipoSolicitante')
  final int iDTipoSolicitante;

  @JsonKey(name: 'IDVulnerabilidad')
  final int iDVulnerabilidad;

  @JsonKey(name: 'Pais')
  final String pais;

  @JsonKey(name: 'RazonSocial')
  final String razonSocial;

  @JsonKey(name: 'Recepcion')
  final String recepcion;

  const PqrdIdentificacionPost({
    required this.atencionEspecial,
    required this.ciudad,
    required this.ciudadano,
    required this.codigoEntidad,
    required this.departamento,
    required this.descripcion,
    required this.documentos,
    required this.iDActividadEconomica,
    required this.iDAsunto,
    required this.iDAtencionEspecial,
    required this.iDAtencionPreferencial,
    required this.iDClasificacion,
    required this.iDDiscapacidad,
    required this.iDEscolaridad,
    required this.iDGenero,
    required this.iDGrupoEtnico,
    required this.iDGrupoInteres,
    required this.iDMedioRespuesta,
    required this.iDNivelExtrato,
    required this.iDNivelSisben,
    required this.iDRangoEdad,
    required this.iDSecretaria,
    required this.iDTipoSolicitante,
    required this.iDVulnerabilidad,
    required this.pais,
    required this.razonSocial,
    required this.recepcion,
  });

  factory PqrdIdentificacionPost.fromJson(Map<String, dynamic> json) =>
      _$PqrdIdentificacionPostFromJson(json);

  Map<String, dynamic> toJson() => _$PqrdIdentificacionPostToJson(this);
}
