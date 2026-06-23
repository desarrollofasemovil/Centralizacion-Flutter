import 'package:json_annotation/json_annotation.dart';

part 'response_pqrd.g.dart';

@JsonSerializable()
class ResponsePQRD {
  @JsonKey(name: 'Estado')
  final bool estado;

  @JsonKey(name: 'Ticket')
  final String ticket;

  const ResponsePQRD({
    required this.estado,
    required this.ticket,
  });

  factory ResponsePQRD.fromJson(Map<String, dynamic> json) =>
      _$ResponsePQRDFromJson(json);

  Map<String, dynamic> toJson() => _$ResponsePQRDToJson(this);
}
