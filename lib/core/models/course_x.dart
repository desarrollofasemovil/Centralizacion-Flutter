import 'package:json_annotation/json_annotation.dart';

part 'course_x.g.dart';

@JsonSerializable()
class CourseX {
  @JsonKey(name: 'get', defaultValue: '')
  final String get;
  final int id;
  final int? municipalityId;
  @JsonKey(defaultValue: '')
  final String name;
  @JsonKey(defaultValue: '')
  final String post;
  @JsonKey(defaultValue: false)
  final bool isActive;

  CourseX({
    required this.get,
    required this.id,
    this.municipalityId,
    required this.name,
    required this.post,
    required this.isActive,
  });

  factory CourseX.fromJson(Map<String, dynamic> json) =>
      _$CourseXFromJson(json);

  Map<String, dynamic> toJson() => _$CourseXToJson(this);
}
