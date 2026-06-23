import 'package:json_annotation/json_annotation.dart';

part 'procedure_application_response.g.dart';

@JsonSerializable()
class ProcedureApplicationResponse {
  @JsonKey(name: 'Estado')
  final String estado;

  @JsonKey(name: 'Ticket')
  final String ticket;

  @JsonKey(name: 'Mensaje')
  final String? mensaje;

  const ProcedureApplicationResponse({
    required this.estado,
    required this.ticket,
    this.mensaje,
  });

  factory ProcedureApplicationResponse.fromJson(Map<String, dynamic> json) =>
      _$ProcedureApplicationResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ProcedureApplicationResponseToJson(this);
}
