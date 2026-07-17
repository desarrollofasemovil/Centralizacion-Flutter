import 'package:json_annotation/json_annotation.dart';

part 'ciudad.g.dart';

/// El backend envía `Id` como número JSON (p. ej. `5001`); el dominio Kotlin lo
/// tipa `String` (Gson coacciona). Con json_serializable el `as String` estricto
/// lanzaba y tumbaba la carga de catálogos/ciudades. Aceptamos number o string.
String pqrdCiudadIdToString(dynamic value) => value?.toString() ?? '';

@JsonSerializable()
class Ciudad {
  @JsonKey(name: 'Id', fromJson: pqrdCiudadIdToString)
  final String id;

  @JsonKey(name: 'NombreCiudad')
  final String nombreCiudad;

  Ciudad({required this.id, required this.nombreCiudad});

  factory Ciudad.fromJson(Map<String, dynamic> json) => _$CiudadFromJson(json);

  Map<String, dynamic> toJson() => _$CiudadToJson(this);
}
