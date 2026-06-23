import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/course_dto.dart';

part 'courses_api_service.g.dart';

@RestApi()
abstract class CourseApiService {
  factory CourseApiService(Dio dio, {String baseUrl}) = _CourseApiService;

  @GET('api/courses')
  Future<ApiResponseWrapper<List<CourseDTO>>> getCourses(
    @Query('municipalityId') int? municipalityId, {
    @Query('courseId') int? courseId,
  });

  @POST('api/courses/register')
  Future<CourseRegistrationResponseDTO> sendCourseRegistration(
    @Body() CourseRegistrationRequestDTO payload,
  );
}
