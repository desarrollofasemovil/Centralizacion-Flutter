import 'package:json_annotation/json_annotation.dart';

part 'people_response.g.dart';

@JsonSerializable()
class PeopleResponse {
  final List<Name>? names;
  final List<Email>? emailAddresses;
  final List<Phone>? phoneNumbers;
  final List<Birthday>? birthdays;
  final List<Address>? addresses;

  const PeopleResponse({
    this.names,
    this.emailAddresses,
    this.phoneNumbers,
    this.birthdays,
    this.addresses,
  });

  factory PeopleResponse.fromJson(Map<String, dynamic> json) =>
      _$PeopleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PeopleResponseToJson(this);
}

@JsonSerializable()
class Name {
  final String? displayName;
  final String? givenName;
  final String? familyName;

  const Name({
    this.displayName,
    this.givenName,
    this.familyName,
  });

  factory Name.fromJson(Map<String, dynamic> json) => _$NameFromJson(json);

  Map<String, dynamic> toJson() => _$NameToJson(this);
}

@JsonSerializable()
class Email {
  final String? value;

  const Email({this.value});

  factory Email.fromJson(Map<String, dynamic> json) => _$EmailFromJson(json);

  Map<String, dynamic> toJson() => _$EmailToJson(this);
}

@JsonSerializable()
class Phone {
  final String? value;

  const Phone({this.value});

  factory Phone.fromJson(Map<String, dynamic> json) => _$PhoneFromJson(json);

  Map<String, dynamic> toJson() => _$PhoneToJson(this);
}

@JsonSerializable()
class Birthday {
  final ContactDate? date;

  const Birthday({this.date});

  factory Birthday.fromJson(Map<String, dynamic> json) =>
      _$BirthdayFromJson(json);

  Map<String, dynamic> toJson() => _$BirthdayToJson(this);
}

@JsonSerializable()
class Address {
  final String? formattedValue;

  const Address({this.formattedValue});

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  Map<String, dynamic> toJson() => _$AddressToJson(this);
}

/// Renamed from [Date] to [ContactDate] to avoid collision with Dart's core [DateTime].
@JsonSerializable()
class ContactDate {
  final int? year;
  final int? month;
  final int? day;

  const ContactDate({
    this.year,
    this.month,
    this.day,
  });

  factory ContactDate.fromJson(Map<String, dynamic> json) =>
      _$ContactDateFromJson(json);

  Map<String, dynamic> toJson() => _$ContactDateToJson(this);
}
