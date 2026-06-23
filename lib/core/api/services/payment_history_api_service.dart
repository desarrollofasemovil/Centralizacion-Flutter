import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/payment_history_dto.dart';
import '../../models/validation_response_dto.dart';

part 'payment_history_api_service.g.dart';

@RestApi()
abstract class PaymentHistoryApiService {
  factory PaymentHistoryApiService(Dio dio, {String baseUrl}) = _PaymentHistoryApiService;

  @GET('api/PaymentHistory/User/{id}')
  Future<PaymentHistoryListDTO> getHistoryPaymentByUser(@Path('id') int id);

  @PUT('{id}/sync-status')
  Future<ValidationResponseDTO> syncPaymentStatus(@Path('id') int idHistory);

  @DELETE('api/PaymentHistory/User/{idUser}/History/{idHistory}')
  Future<ValidationResponseDTO> deleteHistoryByUser(
    @Path('idUser') int idUser,
    @Path('idHistory') int idHistory,
  );

  @POST('api/PaymentHistory/')
  Future<ValidationResponseDTO> createPaymentHistory(@Body() Map<String, dynamic> body);
}
