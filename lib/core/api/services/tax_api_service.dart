import 'package:dio/dio.dart' hide Headers;
import 'package:retrofit/retrofit.dart';

import '../../models/tax_dto.dart';
import '../../models/status_transaction_dto.dart';

part 'tax_api_service.g.dart';

@RestApi()
abstract class TaxApiService {
  factory TaxApiService(Dio dio, {String baseUrl}) = _TaxApiService;

  @POST('ImpuestoEntidad/GetImpuestos')
  Future<TaxQueryResponseDTO> getTaxes(@Body() TaxQueryRequestDTO body);

  @POST('ImpuestoEntidad/GetDownloadPDF')
  Future<String> downloadInvoice(@Body() TaxQueryRequestDTO body);

  @GET('{fileUrl}')
  @DioResponseType(ResponseType.bytes)
  Future<List<int>> downloadFile(@Path('fileUrl') String fileUrl);
}

@RestApi()
abstract class PaymentApiService {
  factory PaymentApiService(Dio dio, {String baseUrl}) = _PaymentApiService;

  @POST('Pasarela/CrearTransaccion')
  Future<BancolombiaGatewayResponseDTO> createTransaction(
    @Body() BancolombiaGatewayRequestDTO body,
  );
}

@RestApi()
abstract class StatusOfPaymentsApiService {
  factory StatusOfPaymentsApiService(Dio dio, {String baseUrl}) =
      _StatusOfPaymentsApiService;

  @POST('Login/authenticate')
  Future<String> authenticate(@Body() Map<String, dynamic> body);

  @GET('transaction')
  Future<StatusTransactionDto> getStatusOfPayment(
    @Header('Authorization') String token,
    @Query('CodigoEntidad') String codigoEntidad,
    @Query('Factura') String factura,
    @Query('IDImpuesto') String idImpuesto,
  );
}
