import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/services/api_providers.dart';
import '../api/services/municipality_api_service.dart';
import '../models/municipality_dto.dart';
import '../theme/design.dart';

/// Repositorio de configuración del municipio. Cachea el [MunicipalityDTO] en
/// memoria por `id` 
class MunicipalityRepository {
  MunicipalityRepository(this._api);

  final MunicipalityApiService _api;
  final Map<int, MunicipalityDTO> _cache = {};

  Future<MunicipalityDTO> getMunicipalityData(int id) async {
    final cached = _cache[id];
    if (cached != null) return cached;
    final dto = await _api.getInfoBy(id);
    _cache[id] = dto;
    return dto;
  }

  void clearCache() => _cache.clear();
}

/// Deriva el [Design] (identidad visual en runtime) desde el DTO —
/// equivalente a `Theme.toDesignModel(alcaldiaName, shield)`.
Design designFromMunicipality(MunicipalityDTO m) => Design.fromThemeHex(
      alcaldiaName: 'Alcaldía de ${m.name}',
      shieldUrl: m.idShield.url,
      primaryColor: m.theme.primaryColor,
      secondaryColor: m.theme.secondaryColor,
      secondaryColorBlack: m.theme.secondaryColorBlack,
      onPrimaryColorLight: m.theme.onPrimaryColorLight,
      onPrimaryColorDark: m.theme.onPrimaryColorDark,
    );

final municipalityRepositoryProvider = Provider<MunicipalityRepository>(
  (ref) => MunicipalityRepository(ref.watch(municipalityApiServiceProvider)),
);

/// Config del municipio por `id` — se carga una vez y se comparte (FRONTEND §2.1).
final municipalityProvider =
    FutureProvider.family<MunicipalityDTO, int>((ref, id) {
  return ref.watch(municipalityRepositoryProvider).getMunicipalityData(id);
});
