import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/email_dto.dart';
import '../../models/validation_response_dto.dart';
import '../../models/validation_response_extra_dto.dart';

part 'emails_api_service.g.dart';

@RestApi()
abstract class SendEmailsApiService {
  factory SendEmailsApiService(Dio dio, {String baseUrl}) = _SendEmailsApiService;

  @POST('api/Email/SendEmail')
  Future<ValidationResponseDTO> sendEmail(@Body() EmailDto emailDto);

  @GET('api/Email/SendEmail/ValidationCode')
  Future<ValidationResponseExtraDto> sendEmailValidationCode(@Query('To') String to);

  @POST('api/Email/SendEmail/Reservations')
  Future<ValidationResponseDTO> sendEmailReservation(@Body() EmailDtoReservations emailDto);

  @POST('api/Email/SendEmail/Panic')
  Future<ValidationResponseDTO> sendPanicEmail(@Body() PanicEmailDto panicDto);
}
