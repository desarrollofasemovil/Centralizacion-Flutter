import 'package:json_annotation/json_annotation.dart';

import 'ciudadano.dart';
import 'documentos.dart';

part 'procedure_application_request.g.dart';

@JsonSerializable()
class ProcedureApplicationRequest {
  final Ciudadano ciudadano;

  @JsonKey(name: 'IDTramite')
  final int idTramite;

  @JsonKey(name: 'CodigoEntidad')
  final String codigoEntidad;

  @JsonKey(name: 'Descripcion')
  final String descripcion;

  final Documentos documentos;

  @JsonKey(name: 'Recepcion')
  final String recepcion;

  const ProcedureApplicationRequest({
    required this.ciudadano,
    required this.idTramite,
    required this.codigoEntidad,
    required this.descripcion,
    required this.documentos,
    required this.recepcion,
  });

  factory ProcedureApplicationRequest.fromJson(Map<String, dynamic> json) =>
      _$ProcedureApplicationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ProcedureApplicationRequestToJson(this);
}
