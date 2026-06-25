import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/services/api_providers.dart';
import '../../../core/models/document_type_dto.dart';
import '../../../core/models/municipalities_dto.dart';

/// Tipos de documento para el paso 2 del registro (`GetDocumentTypes`).
final documentTypesProvider = FutureProvider<List<DocumentTypeDTO>>((ref) {
  return ref.watch(authApiServiceProvider).getDocumentTypes();
});

/// Todos los municipios para el campo "municipio de residencia" del paso 3.
/// Vienen en `result` del wrapper `GetMunicipality` (BACKEND §3.3).
final allMunicipalitiesProvider =
    FutureProvider<List<MunicipalitiesDTO>>((ref) async {
  final res = await ref.watch(municipalityApiServiceProvider).getMunicipality();
  return res.result ?? const [];
});
