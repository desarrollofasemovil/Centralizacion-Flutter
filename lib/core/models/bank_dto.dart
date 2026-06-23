import 'package:json_annotation/json_annotation.dart';

part 'bank_dto.g.dart';

@JsonSerializable()
class BankDTO {
  @JsonKey(name: 'nameBank')
  final String nameBank;

  BankDTO({
    required this.nameBank,
  });

  factory BankDTO.fromJson(Map<String, dynamic> json) =>
      _$BankDTOFromJson(json);

  Map<String, dynamic> toJson() => _$BankDTOToJson(this);
}
