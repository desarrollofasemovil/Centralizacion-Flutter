import 'package:json_annotation/json_annotation.dart';

part 'procedures.g.dart';

@JsonSerializable()
class Procedures {
  final int id;
  final String name;

  Procedures({
    required this.id,
    required this.name,
  });

  factory Procedures.fromJson(Map<String, dynamic> json) =>
      _$ProceduresFromJson(json);

  Map<String, dynamic> toJson() => _$ProceduresToJson(this);
}
