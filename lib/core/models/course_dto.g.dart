// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiResponseWrapper<T> _$ApiResponseWrapperFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => ApiResponseWrapper<T>(
  codeStatus: (json['codeStatus'] as num).toInt(),
  booleanStatus: json['booleanStatus'] as bool,
  sentencesError: json['sentencesError'] as String?,
  result: _$nullableGenericFromJson(json['result'], fromJsonT),
);

Map<String, dynamic> _$ApiResponseWrapperToJson<T>(
  ApiResponseWrapper<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'codeStatus': instance.codeStatus,
  'booleanStatus': instance.booleanStatus,
  'sentencesError': instance.sentencesError,
  'result': _$nullableGenericToJson(instance.result, toJsonT),
};

T? _$nullableGenericFromJson<T>(
  Object? input,
  T Function(Object? json) fromJson,
) => input == null ? null : fromJson(input);

Object? _$nullableGenericToJson<T>(
  T? input,
  Object? Function(T value) toJson,
) => input == null ? null : toJson(input);

CourseDTO _$CourseDTOFromJson(Map<String, dynamic> json) => CourseDTO(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  category: json['category'] as String?,
  availableSlots: (json['availableSlots'] as num?)?.toInt(),
  startDate: json['startDate'] as String?,
  endDate: json['endDate'] as String?,
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$CourseDTOToJson(CourseDTO instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'description': instance.description,
  'category': instance.category,
  'availableSlots': instance.availableSlots,
  'startDate': instance.startDate,
  'endDate': instance.endDate,
  'imageUrl': instance.imageUrl,
};

CourseRegistrationRequestDTO _$CourseRegistrationRequestDTOFromJson(
  Map<String, dynamic> json,
) => CourseRegistrationRequestDTO(
  coursesMunicipalityId: (json['coursesMunicipalityId'] as num).toInt(),
  documentNumber: json['documentNumber'] as String,
  firstName: json['firstName'] as String,
  lastName: json['lastName'] as String,
  age: (json['age'] as num).toInt(),
  email: json['email'] as String,
  municipalityEmail: json['municipalityEmail'] as String?,
  phone: json['phone'] as String,
);

Map<String, dynamic> _$CourseRegistrationRequestDTOToJson(
  CourseRegistrationRequestDTO instance,
) => <String, dynamic>{
  'coursesMunicipalityId': instance.coursesMunicipalityId,
  'documentNumber': instance.documentNumber,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'age': instance.age,
  'email': instance.email,
  'municipalityEmail': instance.municipalityEmail,
  'phone': instance.phone,
};

CourseRegistrationResponseDTO _$CourseRegistrationResponseDTOFromJson(
  Map<String, dynamic> json,
) => CourseRegistrationResponseDTO(message: json['message'] as String);

Map<String, dynamic> _$CourseRegistrationResponseDTOToJson(
  CourseRegistrationResponseDTO instance,
) => <String, dynamic>{'message': instance.message};
