import 'package:json_annotation/json_annotation.dart';
import 'municipality.dart';
import 'social_media_type.dart';

part 'municipality_social_media.g.dart';

@JsonSerializable()
class MunicipalitySocialMedia {
  final int id;
  final bool isActive;
  final Municipality municipality;
  final SocialMediaType socialMediaType;
  final String url;

  MunicipalitySocialMedia({
    required this.id,
    required this.isActive,
    required this.municipality,
    required this.socialMediaType,
    required this.url,
  });

  factory MunicipalitySocialMedia.fromJson(Map<String, dynamic> json) =>
      _$MunicipalitySocialMediaFromJson(json);

  Map<String, dynamic> toJson() => _$MunicipalitySocialMediaToJson(this);
}
