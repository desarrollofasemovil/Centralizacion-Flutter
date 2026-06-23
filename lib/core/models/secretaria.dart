import 'package:json_annotation/json_annotation.dart';

part 'secretaria.g.dart';

/// Puerto de `Secretaria` (pqrddto). Campos en lowerCamelCase con `@JsonKey`
/// para preservar las keys JSON originales y evitar la colisión campo/clase.
@JsonSerializable()
class Secretaria {
  @JsonKey(name: 'IDSecretaria')
  final int idSecretaria;

  @JsonKey(name: 'Direccion')
  final dynamic direccion;

  @JsonKey(name: 'Email')
  final dynamic email;

  @JsonKey(name: 'Estado')
  final dynamic estado;

  @JsonKey(name: 'Horario')
  final dynamic horario;

  @JsonKey(name: 'Secretaria')
  final String secretaria;

  @JsonKey(name: 'Telefono')
  final dynamic telefono;

  const Secretaria({
    required this.idSecretaria,
    required this.direccion,
    required this.email,
    required this.estado,
    required this.horario,
    required this.secretaria,
    required this.telefono,
  });

  factory Secretaria.fromJson(Map<String, dynamic> json) =>
      _$SecretariaFromJson(json);

  Map<String, dynamic> toJson() => _$SecretariaToJson(this);
}
