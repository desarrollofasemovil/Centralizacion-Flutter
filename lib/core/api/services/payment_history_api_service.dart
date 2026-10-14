import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/payment_history_dto.dart';
import '../../models/validation_response_dto.dart';
import '../global_error_interceptor.dart';

part 'payment_history_api_service.g.dart';

@RestApi()
abstract class PaymentHistoryApiService {
  factory PaymentHistoryApiService(Dio dio, {String baseUrl}) = _PaymentHistoryApiService;

  /// Lista directa con pagos, o envelope `404` sin pagos: leer siempre con
  /// [paymentHistoryFromResponse].
  @GET('api/PaymentHistory/User/{id}')
  Future<dynamic> getHistoryPaymentByUser(@Path('id') int id);

  /// Sincroniza un pago contra la pasarela (API `docs/api/payment-history.md`).
  /// Antes apuntaba a `{id}/sync-status` sin el prefijo del controlador, una
  /// ruta que no existe (igual en la app Kotlin): la sincronización a demanda
  /// nunca funcionó y solo el job del servidor actualizaba los estados.
  ///
  /// Aquí el HTTP sí coincide con `codeStatus`: 200 (sincronizado o
  /// reprogramado), 400/404 (no existe), **502** (el banco no respondió, se
  /// reintenta solo) y 500. Ese 502/500 no debe bloquear la app.
  @PUT('api/PaymentHistory/{id}/sync-status')
  @Extra({kAllowServerErrorExtra: true})
  Future<ValidationResponseDTO> syncPaymentStatus(@Path('id') int idHistory);

  @DELETE('api/PaymentHistory/User/{idUser}/History/{idHistory}')
  Future<ValidationResponseDTO> deleteHistoryByUser(
    @Path('idUser') int idUser,
    @Path('idHistory') int idHistory,
  );

  @POST('api/PaymentHistory/')
  Future<ValidationResponseDTO> createPaymentHistory(@Body() Map<String, dynamic> body);
}
