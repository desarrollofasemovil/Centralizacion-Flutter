import 'package:json_annotation/json_annotation.dart';

part 'ciudadano.g.dart';

@JsonSerializable()
class Ciudadano {
  @JsonKey(name: 'Direccion')
  final String direccion;

  @JsonKey(name: 'Email')
  final String email;

  @JsonKey(name: 'Identificacion')
  final String identificacion;

  @JsonKey(name: 'PrimerApellido')
  final String primerApellido;

  @JsonKey(name: 'PrimerNombre')
  final String primerNombre;

  @JsonKey(name: 'SegundoApellido')
  final String segundoApellido;

  @JsonKey(name: 'SegundoNombre')
  final String segundoNombre;

  @JsonKey(name: 'Telefono')
  final String telefono;

  @JsonKey(name: 'TipoDocumento')
  final int tipoDocumento;

  const Ciudadano({
    required this.direccion,
    required this.email,
    required this.identificacion,
    required this.primerApellido,
    required this.primerNombre,
    required this.segundoApellido,
    required this.segundoNombre,
    required this.telefono,
    required this.tipoDocumento,
  });

  factory Ciudadano.fromJson(Map<String, dynamic> json) =>
      _$CiudadanoFromJson(json);

  Map<String, dynamic> toJson() => _$CiudadanoToJson(this);
}
