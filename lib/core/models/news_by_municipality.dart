import 'package:json_annotation/json_annotation.dart';

part 'news_by_municipality.g.dart';

@JsonSerializable()
class NewsByMunicipality {
  @JsonKey(name: 'getUrlNew')
  final String url;

  @JsonKey(name: 'idMunicipality')
  final int idMunicipality;

  NewsByMunicipality({
    required this.url,
    required this.idMunicipality,
  });

  factory NewsByMunicipality.fromJson(Map<String, dynamic> json) =>
      _$NewsByMunicipalityFromJson(json);

  Map<String, dynamic> toJson() => _$NewsByMunicipalityToJson(this);
}
