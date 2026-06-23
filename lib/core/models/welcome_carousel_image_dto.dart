import 'package:json_annotation/json_annotation.dart';

part 'welcome_carousel_image_dto.g.dart';

@JsonSerializable()
class CarouselImage {
  final String imageUrl;
  final String clickUrl;

  CarouselImage({
    required this.imageUrl,
    required this.clickUrl,
  });

  factory CarouselImage.fromJson(Map<String, dynamic> json) =>
      _$CarouselImageFromJson(json);

  Map<String, dynamic> toJson() => _$CarouselImageToJson(this);
}

@JsonSerializable()
class CarouselImageDTO {
  final String imageUrl;
  final String clickUrl;

  CarouselImageDTO({
    required this.imageUrl,
    required this.clickUrl,
  });

  factory CarouselImageDTO.fromJson(Map<String, dynamic> json) =>
      _$CarouselImageDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CarouselImageDTOToJson(this);
}

@JsonSerializable()
class CarouselConfigDTO {
  final List<CarouselImageDTO> images;

  CarouselConfigDTO({
    required this.images,
  });

  factory CarouselConfigDTO.fromJson(Map<String, dynamic> json) =>
      _$CarouselConfigDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CarouselConfigDTOToJson(this);
}
