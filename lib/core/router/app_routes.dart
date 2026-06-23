/// Rutas de la app (go_router). Datos largos (URLs de políticas, JSON de
/// queryFields) NO viajan por la ruta: usar `extra`/estado (CONVENCIONES §7).
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const selectMunicipality = '/select-municipality';
  static const signup = '/signup';

  /// Home del municipio (orquestador "alcaldías"). `:id` = municipalityId.
  static const municipality = '/municipality/:id';

  static String municipalityPath(int id) => '/municipality/$id';
}
