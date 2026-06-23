/// Fuente única de verdad de la identidad de build de cada app (flavor).
///
/// Un flavor define **solo identidad de build**: nombre visible, applicationId/
/// bundleId, ícono, proyecto Firebase y el `municipioId` fijo. Los colores, el
/// escudo y los módulos los sigue definiendo el backend vía
/// `GET /api/Municipality/GetInfoBy{id}` (ver BACKEND §4.1 y §7).
///
/// Regla: nada de `if (flavor == 'manizales')` desperdigado por el código. Un
/// comportamiento nuevo por app = un campo nuevo aquí.
enum Flavor { municipios, manizales }

class FlavorConfig {
  /// Identificador del flavor en ejecución.
  final Flavor flavor;

  /// Label visible de la app.
  final String appName;

  /// `null` => modo selector (Trami App Municipios).
  /// Valor fijo => app individual de un municipio (entra directo a su config).
  final int? fixedMunicipalityId;

  /// Si la app muestra Welcome + selector de municipio.
  final bool showMunicipalitySelector;

  /// Prefijo del tópico FCM por municipio (igual que hoy: `theme_`).
  final String fcmTopicPrefix;

  const FlavorConfig({
    required this.flavor,
    required this.appName,
    required this.fixedMunicipalityId,
    required this.showMunicipalitySelector,
    this.fcmTopicPrefix = 'theme_',
  });

  /// `true` cuando la app entra directo a un municipio fijo (app individual).
  bool get isIndividual => fixedMunicipalityId != null;

  /// Configuración del flavor en ejecución. Se setea en el entrypoint
  /// (`main_*.dart` → `bootstrap`).
  static late FlavorConfig instance;
}
