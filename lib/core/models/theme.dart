import 'package:json_annotation/json_annotation.dart';

part 'theme.g.dart';

@JsonSerializable()
class Theme {
  final String backGroundColor;
  final String onPrimaryColorDark;
  final String onPrimaryColorLight;
  final String primaryColor;
  final String secondaryColor;
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
