import '../analytics/analytics_service.dart';

/// Rutas de la app (go_router). Datos largos (URLs de políticas, JSON de
/// queryFields) NO viajan por la ruta: usar `extra`/estado (CONVENCIONES §7).
class AppRoutes {
  AppRoutes._();

  static const splash = '/';
  static const welcome = '/welcome';
  static const selectMunicipality = '/select-municipality/:departmentId';
  static const signup = '/signup';
  static const recoverPassword = '/recover-password';
  static const changePasswordReset = '/recover-password/change';

  /// Video tutorial desde Bienvenida (sin alcaldía). Los datos del video
  /// (`VideoTutorialArgs`) viajan como `extra`.
  static const videoTutorial = '/video-tutorial';

  /// Home del municipio (orquestador "alcaldías"). `:id` = municipalityId.
  static const municipality = '/municipality/:id';
  
  /// Sub-rutas del municipio
  static const news = '/municipality/:id/news';
  static const taxes = '/municipality/:id/taxes';
  static const pqrd = '/municipality/:id/pqrd';
  /// El certificado viaja como `extra` (`CertificateProcedure`), no en el path.
  static const certificados = '/municipality/:id/certificados';
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
  static const cursos = '/municipality/:id/cursos';
  static const venues = '/municipality/:id/venues';
  static const help = '/municipality/:id/help';
  static const settings = '/municipality/:id/settings';
  static const reminders = '/municipality/:id/reminders';
  static const editProfile = '/municipality/:id/edit-profile';

  /// Tutorial de primer uso. El origen (`TutorialOrigin`) viaja como `extra`.
  static const tutorial = '/municipality/:id/tutorial';

  /// Video tutorial desde Ayuda y Soporte: dentro de la alcaldía, con su tema.
  static const municipalityVideoTutorial = '/municipality/:id/video-tutorial';

  static String selectMunicipalityPath(int departmentId) =>
      '/select-municipality/$departmentId';

  static String municipalityPath(int id) => '/municipality/$id';
  static String newsPath(int id) => '/municipality/$id/news';
  static String taxesPath(int id) => '/municipality/$id/taxes';
  static String pqrdPath(int id) => '/municipality/$id/pqrd';
  static String certificadosPath(int id) => '/municipality/$id/certificados';
  static String serviciosPublicosMenuPath(int id) => '/municipality/$id/servicios-publicos';
  static String pagosPsvPath(int id) => '/municipality/$id/pagos/psv';
  static String pagosProcessingPath(int id) => '/municipality/$id/pagos/processing';

  /// Clave de la URL de la pasarela en el `extra` de [pagosProcessing].
  static const pagosProcessingUrlKey = 'paymentUrl';

  /// Claves de analítica en el `extra` de [pagosProcessing]: de qué flujo viene
  /// el pago ([PaymentOrigin]) y el impuesto, para `pasarela_abierta` y
  /// `pago_verificado`.
  static const pagosProcessingOriginKey = 'origen';
  static const pagosProcessingTaxIdKey = 'impuestoId';

  static Map<String, Object> pagosProcessingExtra(
    String paymentUrl, {
    PaymentOrigin? origin,
    int? taxId,
  }) => {
    pagosProcessingUrlKey: paymentUrl,
    pagosProcessingOriginKey: ?origin,
    pagosProcessingTaxIdKey: ?taxId,
  };
  static String pagosHistoryPath(int id) => '/municipality/$id/pagos/history';
  static String cursosPath(int id) => '/municipality/$id/cursos';
  static String venuesPath(int id) => '/municipality/$id/venues';
  static String helpPath(int id) => '/municipality/$id/help';
  static String settingsPath(int id) => '/municipality/$id/settings';
  static String remindersPath(int id) => '/municipality/$id/reminders';
  static String editProfilePath(int id) => '/municipality/$id/edit-profile';
  static String tutorialPath(int id) => '/municipality/$id/tutorial';
  static String municipalityVideoTutorialPath(int id) =>
      '/municipality/$id/video-tutorial';
}


