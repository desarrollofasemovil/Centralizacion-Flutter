import 'package:json_annotation/json_annotation.dart';

part 'course_dto.g.dart';

// Wrapper genérico de respuesta de la API .NET
@JsonSerializable(genericArgumentFactories: true)
class ApiResponseWrapper<T> {
  @JsonKey(name: 'codeStatus')
  final int codeStatus;

  @JsonKey(name: 'booleanStatus')
  final bool booleanStatus;

  @JsonKey(name: 'sentencesError')
  final String? sentencesError;

  @JsonKey(name: 'result')
  final T? result;

  ApiResponseWrapper({
    required this.codeStatus,
    required this.booleanStatus,
    this.sentencesError,
    this.result,
  });

  factory ApiResponseWrapper.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) =>
      _$ApiResponseWrapperFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseWrapperToJson(this, toJsonT);
}

// DTO para un curso individual (respuesta de la API .NET)
@JsonSerializable()
class CourseDTO {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'title')
  final String title;

  @JsonKey(name: 'description')
  final String? description;

  @JsonKey(name: 'category')
  final String? category;

  @JsonKey(name: 'availableSlots')
  final int? availableSlots;

  @JsonKey(name: 'startDate')
  final String? startDate;

  @JsonKey(name: 'endDate')
  final String? endDate;

  @JsonKey(name: 'imageUrl')
  final String? imageUrl;

  CourseDTO({
    required this.id,
    required this.title,
    this.description,
    this.category,
    this.availableSlots,
    this.startDate,
    this.endDate,
    this.imageUrl,
  });

  factory CourseDTO.fromJson(Map<String, dynamic> json) =>
      _$CourseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CourseDTOToJson(this);
}

// DTO para la solicitud de inscripción (body del POST a la API .NET)
@JsonSerializable()
class CourseRegistrationRequestDTO {
  @JsonKey(name: 'coursesMunicipalityId')
  final int coursesMunicipalityId;

  @JsonKey(name: 'documentNumber')
  final String documentNumber;

  @JsonKey(name: 'firstName')
  final String firstName;

  @JsonKey(name: 'lastName')
  final String lastName;

  @JsonKey(name: 'age')
  final int age;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'municipalityEmail')
  final String? municipalityEmail;

  @JsonKey(name: 'phone')
  final String phone;

  CourseRegistrationRequestDTO({
    required this.coursesMunicipalityId,
    required this.documentNumber,
    required this.firstName,
    required this.lastName,
    required this.age,
    required this.email,
    this.municipalityEmail,
    required this.phone,
  });

  factory CourseRegistrationRequestDTO.fromJson(Map<String, dynamic> json) =>
      _$CourseRegistrationRequestDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CourseRegistrationRequestDTOToJson(this);
}

// Nuevo DTO para capturar el mensaje de éxito del POST según Swagger
@JsonSerializable()
class CourseRegistrationResponseDTO {
  @JsonKey(name: 'message')
  final String message;

  CourseRegistrationResponseDTO({
    required this.message,
  });

  factory CourseRegistrationResponseDTO.fromJson(Map<String, dynamic> json) =>
      _$CourseRegistrationResponseDTOFromJson(json);

  Map<String, dynamic> toJson() => _$CourseRegistrationResponseDTOToJson(this);
}
