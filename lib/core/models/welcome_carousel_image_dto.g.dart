// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'welcome_carousel_image_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CarouselImage _$CarouselImageFromJson(Map<String, dynamic> json) =>
    CarouselImage(
      imageUrl: json['imageUrl'] as String,
      clickUrl: json['clickUrl'] as String,
    );

Map<String, dynamic> _$CarouselImageToJson(CarouselImage instance) =>
    <String, dynamic>{
      'imageUrl': instance.imageUrl,
      'clickUrl': instance.clickUrl,
    };

CarouselImageDTO _$CarouselImageDTOFromJson(Map<String, dynamic> json) =>
    CarouselImageDTO(
      imageUrl: json['imageUrl'] as String,
      clickUrl: json['clickUrl'] as String,
    );

Map<String, dynamic> _$CarouselImageDTOToJson(CarouselImageDTO instance) =>
    <String, dynamic>{
      'imageUrl': instance.imageUrl,
      'clickUrl': instance.clickUrl,
    };

CarouselConfigDTO _$CarouselConfigDTOFromJson(Map<String, dynamic> json) =>
    CarouselConfigDTO(
      images: (json['images'] as List<dynamic>)
          .map((e) => CarouselImageDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CarouselConfigDTOToJson(CarouselConfigDTO instance) =>
    <String, dynamic>{'images': instance.images};
