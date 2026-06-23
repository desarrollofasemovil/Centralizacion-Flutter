import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../../models/department.dart';
import '../../models/municipality.dart';
import '../../models/municipality_dto.dart';
import '../../models/validation_response_dto.dart';

part 'municipality_api_service.g.dart';

/// Servicio del microservicio Centralización para municipios/departamentos
/// (BACKEND §3.3 y §3.4). Base: `NetworkProvider.centralizacionApiUrl`.
@RestApi()
abstract class MunicipalityApiService {
  factory MunicipalityApiService(Dio dio, {String baseUrl}) =
      _MunicipalityApiService;

  /// ⭐ Endpoint central de configuración: theme, escudo, módulos, trámites…
  @GET('/api/Municipality/GetInfoBy{id}')
  Future<MunicipalityDTO> getInfoBy(@Path('id') int id);

  /// Municipios de un departamento (se filtran por `isActive` en el repo).
  @GET('/api/Municipality/ByDepartamet_{id}')
  Future<List<Municipality>> byDepartment(@Path('id') int departmentId);

  /// Lista todos (los municipios vienen en `result` del wrapper).
  @GET('/api/Municipality/GetMunicipality')
  Future<ValidationResponseDTO> getMunicipality();

  /// Departamentos para el selector.
  @GET('/api/Department')
  Future<List<Department>> getDepartments();
}
