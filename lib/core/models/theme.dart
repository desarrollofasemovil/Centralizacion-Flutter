import 'package:json_annotation/json_annotation.dart';

part 'theme.g.dart';

@JsonSerializable()
class Theme {
  @JsonKey(defaultValue: '')
  final String backGroundColor;
  @JsonKey(defaultValue: '')
  final String onPrimaryColorDark;
  @JsonKey(defaultValue: '')
  final String onPrimaryColorLight;
  @JsonKey(defaultValue: '')
  final String primaryColor;
  @JsonKey(defaultValue: '')
  final String secondaryColor;
  @JsonKey(defaultValue: '')
  final String secondaryColorBlack;

  Theme({
    required this.backGroundColor,
    required this.onPrimaryColorDark,
    required this.onPrimaryColorLight,
    required this.primaryColor,
    required this.secondaryColor,
    required this.secondaryColorBlack,
  });

  factory Theme.fromJson(Map<String, dynamic> json) => _$ThemeFromJson(json);
  Map<String, dynamic> toJson() => _$ThemeToJson(this);
}
