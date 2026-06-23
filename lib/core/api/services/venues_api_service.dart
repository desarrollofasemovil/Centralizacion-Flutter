import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/course_dto.dart'; // for ApiResponseWrapper
import '../../models/venue_dto.dart';

part 'venues_api_service.g.dart';

@RestApi()
abstract class VenueApiService {
  factory VenueApiService(Dio dio, {String baseUrl}) = _VenueApiService;

  @GET('api/venues')
  Future<ApiResponseWrapper<List<VenueDTO>>> getVenues(
    @Query('municipalityId') int municipalityId,
    @Query('sportFacilityId') int venueId,
  );

  @GET('api/reservations/user/{documentNumber}/status')
  Future<UserReservationStatusDTO> getUserReservationStatus(
    @Path('documentNumber') String documentNumber,
  );

  @POST('api/reservations')
  Future<ApiResponseWrapper<ReservationResponseDTO>> sendReservation(
    @Body() ReservationRequestDTO reservation,
  );
}
