import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

part 'tramites_api_service.g.dart';

@RestApi()
abstract class TramitesApiService {
  factory TramitesApiService(Dio dio, {String baseUrl}) = _TramitesApiService;

  @GET('api/municipios/{id}/tramites')
  Future<dynamic> getTramitesForMunicipality(
    @Path('id') int municipalityId,
  );
}
