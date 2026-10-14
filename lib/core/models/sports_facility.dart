import 'package:json_annotation/json_annotation.dart';

part 'sports_facility.g.dart';

@JsonSerializable()
class SportsFacility {
  @JsonKey(defaultValue: '')
  final String calendaryPost;
  @JsonKey(name: 'get', defaultValue: '')
  final String get;
  final int id;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: '')
  final String reservationPost;
  @JsonKey(defaultValue: false)
  final bool isActive;

  SportsFacility({
    required this.calendaryPost,
    required this.get,
    required this.id,
    required this.name,
    required this.reservationPost,
    required this.isActive,
  });

  factory SportsFacility.fromJson(Map<String, dynamic> json) =>
      _$SportsFacilityFromJson(json);

  Map<String, dynamic> toJson() => _$SportsFacilityToJson(this);
}
