import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/people_response.dart';

part 'google_api_service.g.dart';

@RestApi()
abstract class GoogleApiService {
  factory GoogleApiService(Dio dio, {String baseUrl}) = _GoogleApiService;

  @GET('v1/people/me?personFields=names,emailAddresses,phoneNumbers,birthdays,addresses')
  Future<PeopleResponse> getProfile(
    @Header('Authorization') String token,
  );
}
