import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/department.dart';
import '../../../core/remote_config/remote_config_service.dart';
import '../data/department_repository.dart';

/// Imagen de anuncio del carrusel lista para UI (desacoplada del DTO de RC).
typedef CarouselItem = ({String imageUrl, String clickUrl});

/// Estado de la pantalla Welcome
class WelcomeState {
  const WelcomeState({
    this.departments = const AsyncValue<List<Department>>.loading(),
    this.query = '',
    this.carouselImages = const [],
  });

  final AsyncValue<List<Department>> departments;
  final String query;
  final List<CarouselItem> carouselImages;

  /// Departamentos filtrados sin acentos + case-insensitive, ordenados por
  /// nombre (equivalente a `filteredDepartments`).
  List<Department> get filteredDepartments {
    final all = departments.value ?? const <Department>[];
    final q = _normalize(query.trim());
    final list = q.isEmpty
        ? [...all]
        : all.where((d) => _normalize(d.name).contains(q)).toList();
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  WelcomeState copyWith({
    AsyncValue<List<Department>>? departments,
    String? query,
    List<CarouselItem>? carouselImages,
  }) =>
      WelcomeState(
        departments: departments ?? this.departments,
        query: query ?? this.query,
        carouselImages: carouselImages ?? this.carouselImages,
      );
}

class WelcomeController extends Notifier<WelcomeState> {
  @override
  WelcomeState build() {
    final images = ref
        .watch(remoteConfigServiceProvider)
        .welcomeCarouselConfig()
        .images
        .map((e) => (imageUrl: e.imageUrl, clickUrl: e.clickUrl))
        .toList();
    _loadDepartments();
    return WelcomeState(carouselImages: images);
  }

  Future<void> _loadDepartments() async {
    try {
      final list = await ref.read(departmentRepositoryProvider).getDepartments();
      state = state.copyWith(departments: AsyncValue.data(list));
    } catch (e, st) {
      state = state.copyWith(departments: AsyncValue.error(e, st));
    }
  }

  void onQueryChanged(String query) => state = state.copyWith(query: query);
}

final welcomeControllerProvider =
    NotifierProvider<WelcomeController, WelcomeState>(WelcomeController.new);

/// Normaliza para búsqueda: minúsculas + sin tildes (equivalente a
/// `removeAccents` del ViewModel original).
String _normalize(String input) {
  const withAccents = 'áàäâãéèëêíìïîóòöôõúùüûñ';
  const without = 'aaaaaeeeeiiiiooooouuuun';
  var s = input.toLowerCase();
  for (var i = 0; i < withAccents.length; i++) {
    s = s.replaceAll(withAccents[i], without[i]);
  }
  return s;
}
