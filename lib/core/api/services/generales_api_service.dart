import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/departamento.dart';
import '../../models/ciudad.dart';

part 'generales_api_service.g.dart';

@RestApi()
abstract class GeneralesApiService {
  factory GeneralesApiService(Dio dio, {String baseUrl}) = _GeneralesApiService;

  @GET('api/Generales/GetDepartamentos')
  Future<List<Departamento>> getDepartamentos();

  @GET('api/Generales/CiudadesXDepartamento')
  Future<List<Ciudad>> getCiudadesPorDepartamento(
    @Query('id_Departamento') String departamentoId,
  );
}
