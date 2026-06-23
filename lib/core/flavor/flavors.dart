import 'flavor_config.dart';

/// Tabla central de flavors — único lugar donde se editan/agregan apps.
/// Para agregar un municipio: añade una `const flavor<Nombre>` aquí y su
/// `lib/main_<nombre>.dart` (ver FLAVORS.md §8 y §11).

const flavorMunicipios = FlavorConfig(
  flavor: Flavor.municipios,
  appName: 'Trami App Municipios',
  fixedMunicipalityId: null, // modo selector (dinámico)
  showMunicipalitySelector: true,
);

const flavorManizales = FlavorConfig(
  flavor: Flavor.manizales,
  appName: 'Trami App Manizales',
  // ⚠️ PENDIENTE: reemplazar por el `id` (Int) real de Manizales que espera
  // `GET /api/Municipality/GetInfoBy{id}` en el backend. Ese número es lo único
  // "de negocio" que hace que la app sea de Manizales (ver FLAVORS.md §8).
  fixedMunicipalityId: 0,
  showMunicipalitySelector: false,
);
