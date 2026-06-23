import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/people_invitated.dart';
import '../../models/validation_response_dto.dart';

part 'people_invitated_api_service.g.dart';

@RestApi()
abstract class PeopleInvitatedApiService {
  factory PeopleInvitatedApiService(Dio dio, {String baseUrl}) = _PeopleInvitatedApiService;

  @POST('api/PeopleInvitated/Create')
  Future<ValidationResponseDTO> createPeopleInvitated(
    @Body() PeopleInvitated body,
  );
}
