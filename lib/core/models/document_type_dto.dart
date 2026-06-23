import 'package:json_annotation/json_annotation.dart';

part 'document_type_dto.g.dart';

@JsonSerializable()
class DocumentTypeDTO {
  final int id;

  @JsonKey(name: 'nameDocument')
  final String name;

  DocumentTypeDTO({
    required this.id,
    required this.name,
  });

  factory DocumentTypeDTO.fromJson(Map<String, dynamic> json) =>
      _$DocumentTypeDTOFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentTypeDTOToJson(this);
}
