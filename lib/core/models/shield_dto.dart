import 'package:json_annotation/json_annotation.dart';

part 'shield_dto.g.dart';

/// Escudo del municipio (parte de `MunicipalityDTO`, ver BACKEND §4.1).
/// DTO de ejemplo que fija la convención: un DTO por archivo, nombres JSON
/// exactos con `@JsonKey(name:)` donde el Kotlin usa `@SerializedName`.
///
/// Kotlin de origen:
/// ```
/// data class ShieldDTO(
///   @SerializedName("nameOfMunicipality") val municipalityName: String,
///   @SerializedName("url") val url: String,
/// )
/// ```
@JsonSerializable()
class ShieldDTO {
  @JsonKey(name: 'nameOfMunicipality')
  final String municipalityName;

  @JsonKey(name: 'url')
  final String url;

  const ShieldDTO({
    required this.municipalityName,
    required this.url,
  });

  factory ShieldDTO.fromJson(Map<String, dynamic> json) =>
      _$ShieldDTOFromJson(json);

  Map<String, dynamic> toJson() => _$ShieldDTOToJson(this);
}
