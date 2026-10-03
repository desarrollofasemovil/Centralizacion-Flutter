import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/course_dto.dart';
import '../../../core/models/user_dto.dart';
import '../../../core/notifications/registration_notifications.dart';
import '../data/courses_repository.dart';
import '../domain/courses_state.dart';

/// Parámetro de la familia: identifica el municipio, el curso y el correo del
/// funcionario municipal (segundo destinatario del correo de inscripción).
@immutable
class CoursesParam {
  final int municipalityId;
  final int courseId;
  final String municipalityEmail;

  const CoursesParam({
    required this.municipalityId,
    required this.courseId,
    required this.municipalityEmail,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CoursesParam &&
          municipalityId == other.municipalityId &&
          courseId == other.courseId &&
          municipalityEmail == other.municipalityEmail;

  @override
  int get hashCode => Object.hash(municipalityId, courseId, municipalityEmail);
}

/// Lógica de Cursos. Port de `CoursesViewModel`.
class CoursesNotifier extends Notifier<CoursesUiState> {
  CoursesNotifier(this.param);

  final CoursesParam param;

  static const _keywords = [
    'Director',
    'Contacto',
    'Celular',
    'Horario',
    'Lugar',
    'Coordinador',
    'Instructor',
    'Profesor',
    'Categoría',
  ];

  CoursesRepository get _repo => ref.read(coursesRepositoryProvider);

  @override
  CoursesUiState build() {
    if (param.municipalityId > 0) {
      Future.microtask(loadCourses);
      return const CoursesUiState(isLoading: true);
    }
    return const CoursesUiState(
      isLoading: false,
      error: 'ID de municipio inválido',
    );
  }

  Future<void> loadCourses() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final courses = await _repo.getCourses(
        param.municipalityId,
        courseId: param.courseId > 0 ? param.courseId : null,
      );
      state = state.copyWith(
        isLoading: false,
        courses: courses,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _message(e));
    }
  }

  void retryLoadCourses() {
    state = state.copyWith(clearError: true);
    if (param.municipalityId > 0) loadCourses();
  }

  // --- Detalles ---
  void onCourseDetailsClick(CourseDTO course) {
    state = state.copyWith(
      selectedCourseForDetails: course,
      parsedCourseDetails: _parseDescription(course.description ?? ''),
    );
  }

  void closeCourseDetails() => state = state.copyWith(clearDetails: true);

  // --- Inscripción ---
  void onRegisterClick(CourseDTO course) =>
      state = state.copyWith(selectedCourse: course);

  void onDialogDismiss() {
    state = state.copyWith(
      clearSelectedCourse: true,
      registrationSuccess: false,
      formState: const RegistrationFormState(),
    );
  }

  void initForm(UserDTO? user) {
    state = state.copyWith(
      formState: RegistrationFormState(
        documentNumber: user?.nationalId ?? '',
        firstName: user?.firstName ?? '',
        lastName: user?.lastName ?? '',
        age: _ageFromBirthDate(user?.birthDate),
        email: user?.email ?? '',
        phone: user?.phoneNumber ?? '',
        isEditable: user == null,
      ),
    );
  }

  // --- Cambios de campos (con el mismo filtrado del original) ---
  void onDocumentNumberChanged(String v) {
    if (v.isEmpty || RegExp(r'^\d+$').hasMatch(v)) {
      _updateForm(
        state.formState.copyWith(
          documentNumber: v,
          clearDocumentNumberError: true,
        ),
      );
    }
  }

  void onFirstNameChanged(String v) {
    if (v.isEmpty || RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ ]+$').hasMatch(v)) {
      _updateForm(
        state.formState.copyWith(firstName: v, clearFirstNameError: true),
      );
    }
  }

  void onLastNameChanged(String v) {
    if (v.isEmpty || RegExp(r'^[A-Za-zÁÉÍÓÚáéíóúÑñ ]+$').hasMatch(v)) {
      _updateForm(
        state.formState.copyWith(lastName: v, clearLastNameError: true),
      );
    }
  }

  void onAgeChanged(String v) {
    if (v.isEmpty || RegExp(r'^\d+$').hasMatch(v)) {
      _updateForm(state.formState.copyWith(age: v, clearAgeError: true));
    }
  }

  void onEmailChanged(String v) =>
      _updateForm(state.formState.copyWith(email: v, clearEmailError: true));

  void _updateForm(RegistrationFormState next) =>
      state = state.copyWith(formState: next);

  Future<void> submitRegistration() async {
    if (!_validate()) return;
    final course = state.selectedCourse;
    if (course == null) return;

    state = state.copyWith(isLoading: true);
    final f = state.formState;
    final payload = CourseRegistrationRequestDTO(
      coursesMunicipalityId: course.id,
      documentNumber: f.documentNumber,
      firstName: f.firstName,
      lastName: f.lastName,
      age: int.tryParse(f.age) ?? 0,
      email: f.email,
      phone: f.phone,
      municipalityEmail: param.municipalityEmail.trim().isEmpty
          ? null
          : param.municipalityEmail,
    );

    try {
      await _repo.registerForCourse(payload);
      state = state.copyWith(isLoading: false, registrationSuccess: true);
      _notifyRegistration(courseTitle: course.title, userName: f.firstName);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _message(e));
    }
  }

  /// Confirmación local (port de `showCourseRegistrationNotification`). Nunca
  /// debe romper ni retrasar la inscripción: no se espera y cualquier fallo se
  /// descarta.
  void _notifyRegistration({
    required String courseTitle,
    required String userName,
  }) {
    try {
      unawaited(
        ref
            .read(registrationNotificationsProvider)
            .showCourseRegistration(courseTitle: courseTitle, userName: userName)
            .catchError((_) => false),
      );
    } catch (e) {
      debugPrint('CoursesNotifier._notifyRegistration error: $e');
    }
  }

  bool _validate() {
    final s = state.formState;
    if (s.documentNumber.trim().isEmpty) {
      _updateForm(
        s.copyWith(documentNumberError: 'El número de documento es requerido'),
      );
      return false;
    }
    if (s.age.trim().isEmpty) {
      _updateForm(s.copyWith(ageError: 'La edad es requerida'));
      return false;
    }
    if (s.firstName.trim().isEmpty) {
      _updateForm(s.copyWith(firstNameError: 'El primer nombre es requerido'));
      return false;
    }
    if (s.firstName.length > 100) {
      _updateForm(
        s.copyWith(
          firstNameError:
              'El primer nombre no puede tener más de 100 caracteres',
        ),
      );
      return false;
    }
    if (s.lastName.trim().isEmpty) {
      _updateForm(s.copyWith(lastNameError: 'El primer apellido es requerido'));
      return false;
    }
    if (s.lastName.length > 100) {
      _updateForm(
        s.copyWith(
          lastNameError:
              'El primer apellido no puede tener más de 100 caracteres',
        ),
      );
      return false;
    }
    if (s.email.trim().isEmpty) {
      _updateForm(s.copyWith(emailError: 'El email es requerido'));
      return false;
    }
    if (!s.email.contains('@')) {
      _updateForm(s.copyWith(emailError: 'El email no es válido'));
      return false;
    }
    if (s.phone.trim().isEmpty) {
      _updateForm(s.copyWith(phoneError: 'El teléfono es requerido'));
      return false;
    }
    if (!RegExp(r'^\d+$').hasMatch(s.phone)) {
      _updateForm(
        s.copyWith(phoneError: 'El teléfono solo puede contener números'),
      );
      return false;
    }
    if (s.phone.length < 7 || s.phone.length > 15) {
      _updateForm(
        s.copyWith(phoneError: 'El teléfono debe tener entre 7 y 15 dígitos'),
      );
      return false;
    }
    return true;
  }

  ParsedCourseDetails _parseDescription(String raw) {
    final details = <String, String>{};
    final remaining = <String>[];
    for (final line in raw.split('\n')) {
      var matched = false;
      for (final keyword in _keywords) {
        final regex = RegExp(
          '^$keyword\\s*[:\\-]\\s*(.*)',
          caseSensitive: false,
        );
        final match = regex.firstMatch(line.trim());
        if (match != null) {
          details[keyword] = match.group(1) ?? '';
          matched = true;
          break;
        }
      }
      if (!matched && line.trim().isNotEmpty) remaining.add(line);
    }
    return ParsedCourseDetails(
      detailsMap: details,
      mainDescription: remaining.join('\n'),
    );
  }

  String _ageFromBirthDate(String? birthDate) {
    if (birthDate == null || birthDate.isEmpty) return '';
    final date = DateTime.tryParse(birthDate);
    if (date == null) return '';
    final now = DateTime.now();
    var age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }
    return age < 0 ? '' : age.toString();
  }

  String _message(Object e) => e is Exception
      ? e.toString().replaceFirst('Exception: ', '')
      : e.toString();
}

final coursesNotifierProvider =
    NotifierProvider.family<CoursesNotifier, CoursesUiState, CoursesParam>(
      CoursesNotifier.new,
    );
