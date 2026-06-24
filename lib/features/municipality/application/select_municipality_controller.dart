import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/municipality.dart';
import '../../../core/storage/user_preferences.dart';
import '../data/municipality_list_repository.dart';

/// Estado de la selección de municipio — equivalente a `SelectMunUiState`
/// (`SelectMunViewModel` del proyecto Kotlin). La pantalla es "tonta"
/// (CONVENCIONES §3).
class SelectMunicipalityState {
  const SelectMunicipalityState({
    this.municipalities = const AsyncValue<List<Municipality>>.loading(),
    this.query = '',
    this.selected,
    this.savePreference = true,
  });

  final AsyncValue<List<Municipality>> municipalities;
  final String query;
  final Municipality? selected;
  final bool savePreference;

  /// Municipios filtrados sin acentos + case-insensitive, ordenados por nombre.
  List<Municipality> get filteredMunicipalities {
    final all = municipalities.valueOrNull ?? const <Municipality>[];
    final q = _normalize(query.trim());
    final list = q.isEmpty
        ? [...all]
        : all.where((m) => _normalize(m.name).contains(q)).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  SelectMunicipalityState copyWith({
    AsyncValue<List<Municipality>>? municipalities,
    String? query,
    Municipality? selected,
    bool clearSelected = false,
    bool? savePreference,
  }) =>
      SelectMunicipalityState(
        municipalities: municipalities ?? this.municipalities,
        query: query ?? this.query,
        selected: clearSelected ? null : (selected ?? this.selected),
        savePreference: savePreference ?? this.savePreference,
      );
}

class SelectMunicipalityController extends Notifier<SelectMunicipalityState> {
  int _departmentId = 0;

  @override
  SelectMunicipalityState build() => const SelectMunicipalityState();

  /// Carga los municipios del departamento elegido en Welcome (equivalente al
  /// `init` que lee `departmentId` del `SavedStateHandle`).
  Future<void> load(int departmentId) async {
    _departmentId = departmentId;
    state = const SelectMunicipalityState(); // reinicia query/selección/guardar
    try {
      final list = await ref
          .read(municipalityListRepositoryProvider)
          .getByDepartment(departmentId);
      state = state.copyWith(municipalities: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(municipalities: AsyncValue.error(e, st));
    }
  }

  void onQueryChanged(String query) {
    final keepSelected = state.selected?.name == query;
    state = state.copyWith(query: query, clearSelected: !keepSelected);
  }

  void onMunicipalitySelected(Municipality municipality) {
    state = state.copyWith(selected: municipality, query: municipality.name);
  }

  void onSavePreferenceChanged(bool value) =>
      state = state.copyWith(savePreference: value);

  /// Persiste la ubicación elegida (equivalente a `onContinueClicked`).
  Future<void> confirm() async {
    final municipality = state.selected;
    if (municipality == null) return;
    await ref.read(userPreferencesProvider).saveLocation(
          departmentId: _departmentId,
          municipalityId: municipality.id,
          municipio: municipality.name,
          guardar: state.savePreference,
        );
  }
}

final selectMunicipalityControllerProvider =
    NotifierProvider<SelectMunicipalityController, SelectMunicipalityState>(
  SelectMunicipalityController.new,
);

/// Normaliza para búsqueda: minúsculas + sin tildes.
String _normalize(String input) {
  const withAccents = 'áàäâãéèëêíìïîóòöôõúùüûñ';
  const without = 'aaaaaeeeeiiiiooooouuuun';
  var s = input.toLowerCase();
  for (var i = 0; i < withAccents.length; i++) {
    s = s.replaceAll(withAccents[i], without[i]);
  }
  return s;
}
