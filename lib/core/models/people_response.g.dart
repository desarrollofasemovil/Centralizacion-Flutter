// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'people_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PeopleResponse _$PeopleResponseFromJson(Map<String, dynamic> json) =>
    PeopleResponse(
      names: (json['names'] as List<dynamic>?)
          ?.map((e) => Name.fromJson(e as Map<String, dynamic>))
          .toList(),
      emailAddresses: (json['emailAddresses'] as List<dynamic>?)
          ?.map((e) => Email.fromJson(e as Map<String, dynamic>))
          .toList(),
      phoneNumbers: (json['phoneNumbers'] as List<dynamic>?)
          ?.map((e) => Phone.fromJson(e as Map<String, dynamic>))
          .toList(),
      birthdays: (json['birthdays'] as List<dynamic>?)
          ?.map((e) => Birthday.fromJson(e as Map<String, dynamic>))
          .toList(),
      addresses: (json['addresses'] as List<dynamic>?)
          ?.map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PeopleResponseToJson(PeopleResponse instance) =>
    <String, dynamic>{
      'names': instance.names,
      'emailAddresses': instance.emailAddresses,
      'phoneNumbers': instance.phoneNumbers,
      'birthdays': instance.birthdays,
      'addresses': instance.addresses,
    };

Name _$NameFromJson(Map<String, dynamic> json) => Name(
  displayName: json['displayName'] as String?,
  givenName: json['givenName'] as String?,
  familyName: json['familyName'] as String?,
);

Map<String, dynamic> _$NameToJson(Name instance) => <String, dynamic>{
  'displayName': instance.displayName,
  'givenName': instance.givenName,
  'familyName': instance.familyName,
};

Email _$EmailFromJson(Map<String, dynamic> json) =>
    Email(value: json['value'] as String?);

Map<String, dynamic> _$EmailToJson(Email instance) => <String, dynamic>{
  'value': instance.value,
};

Phone _$PhoneFromJson(Map<String, dynamic> json) =>
    Phone(value: json['value'] as String?);

Map<String, dynamic> _$PhoneToJson(Phone instance) => <String, dynamic>{
  'value': instance.value,
};

Birthday _$BirthdayFromJson(Map<String, dynamic> json) => Birthday(
  date: json['date'] == null
      ? null
      : ContactDate.fromJson(json['date'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BirthdayToJson(Birthday instance) => <String, dynamic>{
  'date': instance.date,
};

Address _$AddressFromJson(Map<String, dynamic> json) =>
    Address(formattedValue: json['formattedValue'] as String?);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'formattedValue': instance.formattedValue,
};

ContactDate _$ContactDateFromJson(Map<String, dynamic> json) => ContactDate(
  year: (json['year'] as num?)?.toInt(),
  month: (json['month'] as num?)?.toInt(),
  day: (json['day'] as num?)?.toInt(),
);

Map<String, dynamic> _$ContactDateToJson(ContactDate instance) =>
    <String, dynamic>{
      'year': instance.year,
      'month': instance.month,
      'day': instance.day,
    };
