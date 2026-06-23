/// Rutas de la app (go_router). Datos largos (URLs de políticas, JSON de
/// queryFields) NO viajan por la ruta: usar `extra`/estado (CONVENCIONES §7).
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const selectMunicipality = '/select-municipality';
  static const loginOptions = '/login-options';
  static const login = '/login';
  static const signup = '/signup';
  static const recoverPassword = '/recover-password';

  /// Home del municipio (orquestador "alcaldías"). `:id` = municipalityId.
  static const municipality = '/municipality/:id';
  
  /// Sub-rutas del municipio
  static const news = '/municipality/:id/news';
  static const taxes = '/municipality/:id/taxes';
  static const pqrd = '/municipality/:id/pqrd';

  static String municipalityPath(int id) => '/municipality/$id';
  static String newsPath(int id) => '/municipality/$id/news';
  static String taxesPath(int id) => '/municipality/$id/taxes';
  static String pqrdPath(int id) => '/municipality/$id/pqrd';
}

