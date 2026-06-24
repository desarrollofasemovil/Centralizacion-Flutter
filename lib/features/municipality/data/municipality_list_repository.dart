import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/municipality_api_service.dart';
import '../../../core/models/municipality.dart';

/// Capa de datos del feature municipality: municipios de un departamento.
/// Filtra `isActive` como indica el contrato del servicio (CONVENCIONES §4, §10).
class MunicipalityListRepository {
  MunicipalityListRepository(this._api);

  final MunicipalityApiService _api;

  Future<List<Municipality>> getByDepartment(int departmentId) async {
    final list = await _api.byDepartment(departmentId);
    return list.where((m) => m.isActive).toList();
  }
}

final municipalityListRepositoryProvider = Provider<MunicipalityListRepository>(
  (ref) => MunicipalityListRepository(ref.watch(municipalityApiServiceProvider)),
);
