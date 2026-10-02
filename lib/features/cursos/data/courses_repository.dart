import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/courses_api_service.dart';
import '../../../core/models/course_dto.dart';

/// Capa de datos de Cursos. Envuelve [CourseApiService] (`api/courses`) —
/// equivalente a `CourseRepositoryImpl` del original. Desempaqueta el
/// `ApiResponseWrapper` y propaga el mensaje de error del backend.
class CoursesRepository {
  CoursesRepository(this._api);

  final CourseApiService _api;

  Future<List<CourseDTO>> getCourses(
    int municipalityId, {
    int? courseId,
  }) async {
    final response = await _api.getCourses(municipalityId, courseId: courseId);
    if (!response.booleanStatus) {
      throw Exception(
        response.sentencesError ?? 'Error desconocido en el servidor',
      );
    }
    return response.result ?? const [];
  }

  /// Devuelve el mensaje de éxito del backend.
  Future<String> registerForCourse(CourseRegistrationRequestDTO payload) async {
    final response = await _api.sendCourseRegistration(payload);
    return response.message;
  }
}

final coursesRepositoryProvider = Provider<CoursesRepository>(
  (ref) => CoursesRepository(ref.watch(courseApiServiceProvider)),
);
