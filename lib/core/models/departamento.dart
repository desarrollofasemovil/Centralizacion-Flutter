import 'package:json_annotation/json_annotation.dart';

part 'departamento.g.dart';

/// El backend (`autoliquidables.1cero1.com/api/Generales/GetDepartamentos`)
/// envía `Id` como número JSON (p. ej. `5`), aunque el dominio Kotlin lo tipa
/// como `String` (Gson lo coacciona sin quejarse). Con json_serializable el
/// `as String` estricto lanzaba `type 'int' is not a subtype of type 'String'`
/// y, al ir dentro del `Future.wait` de `loadCatalogData`, tumbaba TODOS los
/// selects. Aceptamos number o string y lo normalizamos a `String`.
String pqrdIdToString(dynamic value) => value?.toString() ?? '';

@JsonSerializable()
class Departamento {
  @JsonKey(name: 'Id', fromJson: pqrdIdToString)
  final String id;

  @JsonKey(name: 'NombreDepartamento')
  final String nombreDepartamento;

  Departamento({required this.id, required this.nombreDepartamento});

  factory Departamento.fromJson(Map<String, dynamic> json) =>
      _$DepartamentoFromJson(json);

  Map<String, dynamic> toJson() => _$DepartamentoToJson(this);
}
