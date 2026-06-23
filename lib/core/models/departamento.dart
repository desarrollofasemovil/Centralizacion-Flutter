import 'package:json_annotation/json_annotation.dart';

part 'departamento.g.dart';

@JsonSerializable()
class Departamento {
  @JsonKey(name: 'Id')
  final String id;

  @JsonKey(name: 'NombreDepartamento')
  final String nombreDepartamento;

  Departamento({
    required this.id,
    required this.nombreDepartamento,
  });

  factory Departamento.fromJson(Map<String, dynamic> json) =>
      _$DepartamentoFromJson(json);

  Map<String, dynamic> toJson() => _$DepartamentoToJson(this);
}
