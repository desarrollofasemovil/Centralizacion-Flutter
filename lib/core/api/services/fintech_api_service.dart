import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/tax_dto.dart'; // FintechTransactionRequestDTO and FintechTransactionResponseDTO are in tax_dto.dart

part 'fintech_api_service.g.dart';

@RestApi()
abstract class FintechPaymentsApiService {
  factory FintechPaymentsApiService(Dio dio, {String baseUrl}) = _FintechPaymentsApiService;

  @POST('api/Fintech/transactionFintech/{id}')
  Future<FintechTransactionResponseDTO> transactionFintech(
    @Path('id') int id,
    @Body() FintechTransactionRequestDTO body,
  );
}
