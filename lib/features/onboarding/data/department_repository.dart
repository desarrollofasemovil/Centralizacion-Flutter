import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/api/services/municipality_api_service.dart';
import '../../../core/models/department.dart';

/// Capa de datos del feature onboarding: departamentos para el selector.
/// Envuelve [MunicipalityApiService] 
class DepartmentRepository {
  DepartmentRepository(this._api);

  final MunicipalityApiService _api;

  Future<List<Department>> getDepartments() => _api.getDepartments();
}

final departmentRepositoryProvider = Provider<DepartmentRepository>(
  (ref) => DepartmentRepository(ref.watch(municipalityApiServiceProvider)),
);
