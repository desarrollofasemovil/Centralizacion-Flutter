import 'package:json_annotation/json_annotation.dart';
import 'municipality.dart';
import 'social_media_type.dart';

part 'municipality_social_media.g.dart';

/// `socialMediaType` nulo se lee como un tipo vacío (id 0) en vez de romper
/// `GetInfoBy{id}`.
SocialMediaType _socialMediaTypeOrEmpty(Map<String, dynamic>? json) =>
    SocialMediaType.fromJson(json ?? const <String, dynamic>{});

@JsonSerializable()
class MunicipalitySocialMedia {
  final int id;
  @JsonKey(defaultValue: false)
  final bool isActive;
  final Municipality? municipality;
  @JsonKey(fromJson: _socialMediaTypeOrEmpty)
  final SocialMediaType socialMediaType;
  @JsonKey(defaultValue: '')
  final String url;

  MunicipalitySocialMedia({
    required this.id,
    required this.isActive,
    this.municipality,
    required this.socialMediaType,
    required this.url,
  });

  factory MunicipalitySocialMedia.fromJson(Map<String, dynamic> json) =>
      _$MunicipalitySocialMediaFromJson(json);

  Map<String, dynamic> toJson() => _$MunicipalitySocialMediaToJson(this);
}
