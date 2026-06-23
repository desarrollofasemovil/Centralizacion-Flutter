import 'package:json_annotation/json_annotation.dart';

part 'municipalities_dto.g.dart';

/// Municipio en la lista (`ValidationResponseDTO.result`). Puerto de
/// `MunicipalitiesDTO` (`domain/model/Municipality.kt`). Sin `@SerializedName`:
/// Gson usa los nombres de campo tal cual.
@JsonSerializable()
class MunicipalitiesDTO {
  final int id;
  final String name;

  MunicipalitiesDTO({required this.id, required this.name});

  factory MunicipalitiesDTO.fromJson(Map<String, dynamic> json) =>
      _$MunicipalitiesDTOFromJson(json);

  Map<String, dynamic> toJson() => _$MunicipalitiesDTOToJson(this);
}
