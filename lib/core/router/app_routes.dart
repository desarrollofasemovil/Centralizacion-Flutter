/// Rutas de la app (go_router). Datos largos (URLs de políticas, JSON de
/// queryFields) NO viajan por la ruta: usar `extra`/estado (CONVENCIONES §7).
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const selectMunicipality = '/select-municipality/:departmentId';
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
  static const certificados = '/municipality/:id/certificados/:entityCode/:procedureId/:integrationType';
  static const serviciosPublicosMenu = '/municipality/:id/servicios-publicos';
  static const serviciosPublicosSelectEntity = '/municipality/:id/servicios-publicos/select-entity';
  static const serviciosPublicosInstructions = '/municipality/:id/servicios-publicos/scanner-instructions';
  static const serviciosPublicosScanner = '/municipality/:id/servicios-publicos/scanner';
  static const serviciosPublicosForm = '/municipality/:id/servicios-publicos/form/:factura/:valor/:fechaVencimiento';
  static const serviciosPublicosHistory = '/municipality/:id/servicios-publicos/history';
  static const serviciosPublicosBillDetails = '/municipality/:id/servicios-publicos/bill-details';
  static const pagosPsv = '/municipality/:id/pagos/psv';
  static const pagosProcessing = '/municipality/:id/pagos/processing';
  static const pagosHistory = '/municipality/:id/pagos/history';

  static String selectMunicipalityPath(int departmentId) =>
      '/select-municipality/$departmentId';

  static String municipalityPath(int id) => '/municipality/$id';
  static String newsPath(int id) => '/municipality/$id/news';
  static String taxesPath(int id) => '/municipality/$id/taxes';
  static String pqrdPath(int id) => '/municipality/$id/pqrd';
  static String certificadosPath(int id, String entityCode, int procedureId, String integrationType) =>
      '/municipality/$id/certificados/$entityCode/$procedureId/$integrationType';
  static String serviciosPublicosMenuPath(int id) => '/municipality/$id/servicios-publicos';
  static String pagosPsvPath(int id) => '/municipality/$id/pagos/psv';
  static String pagosProcessingPath(int id) => '/municipality/$id/pagos/processing';
  static String pagosHistoryPath(int id) => '/municipality/$id/pagos/history';
}


