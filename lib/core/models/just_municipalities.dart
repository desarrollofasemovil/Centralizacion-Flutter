import 'package:json_annotation/json_annotation.dart';

part 'just_municipalities.g.dart';

@JsonSerializable()
class JustMunicipalities {
  final int? id;
  final String? name;

  const JustMunicipalities({
    this.id,
    this.name,
  });

  factory JustMunicipalities.fromJson(Map<String, dynamic> json) =>
      _$JustMunicipalitiesFromJson(json);

  Map<String, dynamic> toJson() => _$JustMunicipalitiesToJson(this);
}
