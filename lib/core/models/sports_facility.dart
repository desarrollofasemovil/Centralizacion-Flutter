import 'package:json_annotation/json_annotation.dart';

part 'sports_facility.g.dart';

@JsonSerializable()
class SportsFacility {
  final String calendaryPost;
  @JsonKey(name: 'get')
  final String get;
  final int id;
  final String name;
  final String reservationPost;
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
