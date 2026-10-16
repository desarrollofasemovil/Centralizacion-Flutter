import 'package:json_annotation/json_annotation.dart';

part 'procedure_application_response.g.dart';

/// `tramitesservices` responde `"Estado": true` (booleano JSON, igual que en la
/// PQRD). El original lo declara `String` y funciona porque Gson convierte el
/// booleano en `"true"`; aquí `as String` reventaba al finalizar el
/// certificado. Se acepta el booleano y, por si acaso, el texto `"true"`.
bool _estadoFromJson(Object? value) =>
    value == true || (value is String && value.trim().toLowerCase() == 'true');

String _textFromJson(Object? value) => value == null ? '' : value.toString();

String? _optionalTextFromJson(Object? value) => value?.toString();

@JsonSerializable()
class ProcedureApplicationResponse {
  @JsonKey(name: 'Estado', fromJson: _estadoFromJson)
  final bool estado;

  @JsonKey(name: 'Ticket', fromJson: _textFromJson)
  final String ticket;

  @JsonKey(name: 'Mensaje', fromJson: _optionalTextFromJson)
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
