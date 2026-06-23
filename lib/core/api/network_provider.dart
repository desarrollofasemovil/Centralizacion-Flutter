/// Las 6 base URLs de los microservicios (puerto de `NetworkProvider.kt`).
///
/// El backend se consume **sin cambios** (BACKEND §2). Todas son HTTPS (iOS lo
/// exige). La base URL local HTTP comentada del proyecto Android
/// (`http://192.168.20.198:45600/`) y `usesCleartextTraffic` NO se portan
/// (CLAUDE.md regla 6).
class NetworkProvider {
  NetworkProvider._();

  /// API principal: usuarios, auth, municipios, departamentos, recordatorios,
  /// historial de pagos, emails, fintech, personas invitadas. Es la base del
  /// Retrofit "principal".
  static const String centralizacionApiUrl = 'https://apicentralizate.1cero1.com/';

  /// Impuestos (consulta + PDF) y pasarela de pago Bancolombia.
  static const String taxApiUrl = 'https://apidatamovil.1cero1.com/api/';

  /// PQRD (listados + inserción) y solicitud de trámites.
  static const String pqrdApiUrl = 'https://tramitesservices.1cero1.com/ApiTramites/api/';

  /// Generales: departamentos y ciudades por departamento (formularios PQRD/registro).
  static const String autoliquidablesApiUrl = 'https://autoliquidables.1cero1.com/';

  /// Google People API — perfil del usuario tras login con Google.
  static const String googleApiUrl = 'https://people.googleapis.com/';

  /// Google Weather API. **Deshabilitado** en el proyecto original (clima
  /// comentado en `MunicipalityViewModel`). Decidir en migración si se reactiva.
  static const String googleWeatherApiUrl = 'https://weather.googleapis.com/';
}
