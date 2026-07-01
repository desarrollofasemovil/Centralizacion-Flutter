import 'package:flutter/foundation.dart';

import '../../../core/models/course_dto.dart';

/// Detalles del curso separados de la descripción cruda (keywords → mapa).
/// Port de `ParsedCourseDetails`.
@immutable
class ParsedCourseDetails {
  final Map<String, String> detailsMap;
  final String mainDescription;

  const ParsedCourseDetails({
    required this.detailsMap,
    required this.mainDescription,
  });
}

/// Estado del formulario de inscripción. Port de `RegistrationFormState`.
@immutable
class RegistrationFormState {
  final String documentNumber;
  final String? documentNumberError;
  final String firstName;
  final String? firstNameError;
  final String lastName;
  final String? lastNameError;
  final String age;
  final String? ageError;
  final String email;
  final String? emailError;
  final String phone;
  final String? phoneError;
  final bool isEditable;

  const RegistrationFormState({
    this.documentNumber = '',
    this.documentNumberError,
    this.firstName = '',
    this.firstNameError,
    this.lastName = '',
    this.lastNameError,
    this.age = '',
    this.ageError,
    this.email = '',
    this.emailError,
    this.phone = '',
    this.phoneError,
    this.isEditable = true,
  });

  RegistrationFormState copyWith({
    String? documentNumber,
    String? documentNumberError,
    String? firstName,
    String? firstNameError,
    String? lastName,
    String? lastNameError,
    String? age,
    String? ageError,
    String? email,
    String? emailError,
    String? phone,
    String? phoneError,
    bool? isEditable,
    bool clearDocumentNumberError = false,
    bool clearFirstNameError = false,
    bool clearLastNameError = false,
    bool clearAgeError = false,
    bool clearEmailError = false,
    bool clearPhoneError = false,
  }) {
    return RegistrationFormState(
      documentNumber: documentNumber ?? this.documentNumber,
      documentNumberError: clearDocumentNumberError
          ? null
          : (documentNumberError ?? this.documentNumberError),
      firstName: firstName ?? this.firstName,
      firstNameError:
          clearFirstNameError ? null : (firstNameError ?? this.firstNameError),
      lastName: lastName ?? this.lastName,
      lastNameError:
          clearLastNameError ? null : (lastNameError ?? this.lastNameError),
      age: age ?? this.age,
      ageError: clearAgeError ? null : (ageError ?? this.ageError),
      email: email ?? this.email,
      emailError: clearEmailError ? null : (emailError ?? this.emailError),
      phone: phone ?? this.phone,
      phoneError: clearPhoneError ? null : (phoneError ?? this.phoneError),
      isEditable: isEditable ?? this.isEditable,
    );
  }
}

/// Estado de la pantalla de Cursos. Port de `CoursesUiState`.
@immutable
class CoursesUiState {
  final bool isLoading;
  final List<CourseDTO> courses;
  final String? error;
  final CourseDTO? selectedCourse;
  final bool registrationSuccess;
  final CourseDTO? selectedCourseForDetails;
  final ParsedCourseDetails? parsedCourseDetails;
  final RegistrationFormState formState;

  const CoursesUiState({
    this.isLoading = true,
    this.courses = const [],
    this.error,
    this.selectedCourse,
    this.registrationSuccess = false,
    this.selectedCourseForDetails,
    this.parsedCourseDetails,
    this.formState = const RegistrationFormState(),
  });

  CoursesUiState copyWith({
    bool? isLoading,
    List<CourseDTO>? courses,
    String? error,
    CourseDTO? selectedCourse,
    bool? registrationSuccess,
    CourseDTO? selectedCourseForDetails,
    ParsedCourseDetails? parsedCourseDetails,
    RegistrationFormState? formState,
    bool clearError = false,
    bool clearSelectedCourse = false,
    bool clearDetails = false,
  }) {
    return CoursesUiState(
      isLoading: isLoading ?? this.isLoading,
      courses: courses ?? this.courses,
      error: clearError ? null : (error ?? this.error),
      selectedCourse:
          clearSelectedCourse ? null : (selectedCourse ?? this.selectedCourse),
      registrationSuccess: registrationSuccess ?? this.registrationSuccess,
      selectedCourseForDetails: clearDetails
          ? null
          : (selectedCourseForDetails ?? this.selectedCourseForDetails),
      parsedCourseDetails: clearDetails
          ? null
          : (parsedCourseDetails ?? this.parsedCourseDetails),
      formState: formState ?? this.formState,
    );
  }
}
