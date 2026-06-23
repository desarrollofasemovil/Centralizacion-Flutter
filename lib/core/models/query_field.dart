import 'package:json_annotation/json_annotation.dart';
import 'municipality.dart';

part 'query_field.g.dart';

@JsonSerializable()
class QueryField {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'queryFieldType')
  final String queryFieldType;

  @JsonKey(name: 'fieldName')
  final String fieldName;

  @JsonKey(name: 'municipality')
  final Municipality? municipality;

  QueryField({
    required this.id,
    required this.queryFieldType,
    required this.fieldName,
    this.municipality,
  });

  factory QueryField.fromJson(Map<String, dynamic> json) =>
      _$QueryFieldFromJson(json);

  Map<String, dynamic> toJson() => _$QueryFieldToJson(this);
}
