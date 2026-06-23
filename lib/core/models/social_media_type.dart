import 'package:json_annotation/json_annotation.dart';

part 'social_media_type.g.dart';

@JsonSerializable()
class SocialMediaType {
  final int id;
  final String name;

  SocialMediaType({
    required this.id,
    required this.name,
  });

  factory SocialMediaType.fromJson(Map<String, dynamic> json) =>
      _$SocialMediaTypeFromJson(json);

  Map<String, dynamic> toJson() => _$SocialMediaTypeToJson(this);
}
