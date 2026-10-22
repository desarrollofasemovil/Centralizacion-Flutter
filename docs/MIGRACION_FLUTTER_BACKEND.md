# Trami App — Documento BACKEND (servicios que consume la app)

> **Propósito de este documento.** Describe TODO lo que la app actual (Trami App Municipios, Android/Kotlin) consume del backend: APIs, base URLs, endpoints, contratos de datos (DTOs), autenticación, y el uso real de Firebase. Está pensado para alimentar agentes de IA que asistirán la **migración a Flutter desde cero**, manteniendo el mismo backend **sin cambios** (`Backend changes: sin_cambios`).
>
> Documento hermano: `MIGRACION_FLUTTER_FRONTEND.md` (cómo la app se comporta con lo que recibe).
>
> **Decisión de arquitectura confirmada por el equipo:** se crea un proyecto Flutter **nuevo desde cero**, manteniendo la versión Android actual en paralelo. Prioridad #1: **Trami App Manizales** (iOS + Android). Las apps individuales por municipio salen de la misma base de código Flutter.

---

## 0. Hechos clave que NO se deben asumir mal

Estos puntos fueron confirmados explícitamente y corrigen suposiciones comunes:

1. **El backend (la API) define los colores, el escudo y los módulos de cada municipio**, NO Firebase y NO el flavor. Esto llega en el objeto `MunicipalityDTO` del endpoint `GET /api/Municipality/GetInfoBy{id}`. (Ver §4.1).
2. **Firebase NO define identidad visual ni módulos.** Firebase Remote Config solo se usa para: imágenes de anuncios, estado global de la app (mantenimiento/forzar actualización), y un booleano de redirección al inicio. (Ver §6).
3. **Hay dos caminos de autenticación distintos y paralelos:**
   - Login **nativo** (correo + contraseña) → contra la API propia (`POST /api/Auth`). **No usa Firebase Auth.**
   - Login con **Google** → único caso que usa Firebase Auth + Google Sign-In.
   (Ver §5).
4. **El backend se consume TAL CUAL en Flutter.** No hay refactor de backend planeado para Manizales. Cambios futuros para otras alcaldías son probables pero aún sin especificación.
5. **Existen 6 base URLs distintas** (microservicios separados). No es una sola API. (Ver §2).

---

## 1. Capa de red — arquitectura actual

```
NetworkProvider (object con las 6 base URLs constantes)
        │
        ▼
NetworkModule (Hilt) ──> provee OkHttpClient único + Retrofit "principal"
        │                  · timeouts 40s (connect/call/read/write)
        │                  · HttpLoggingInterceptor (BODY solo en DEBUG)
        │                  · GlobalErrorInterceptor (manejo global de errores)
        ▼
ApiFactory (createService<T>(baseUrl, clazz))
        │   reutiliza el MISMO OkHttpClient para todas las base URLs
        ▼
AppModule (Hilt) ──> instancia cada *ApiService con su base URL via ApiFactory
```

**Equivalente Flutter sugerido (sin imponer):** un único `Dio` con `BaseOptions(connectTimeout/receiveTimeout: 40s)` + un `Interceptor` global equivalente a `GlobalErrorInterceptor`, y una factory que cree clientes `retrofit_dart` por base URL. Converter actual = **Gson**; en Flutter = `json_serializable`.

### 1.1 GlobalErrorInterceptor (comportamiento a replicar)

Intercepta TODAS las respuestas y excepciones de red, y publica un estado global en `AppStatusManager` (un `StateFlow<AppStatus>` singleton). Reglas exactas:

- Respuesta con código `500..599` → `AppStatus(type=SERVER_ERROR, isBlocking=true)`, mensaje "El servicio no está disponible…".
- `ConnectException` → "Servicio No Disponible" / "No se pudo establecer conexión." (no bloqueante).
- `SocketTimeoutException` → "Tiempo agotado" / "El servidor tardó demasiado en responder."
- `UnknownHostException` → "Sin conexión" / "Verifica tu conexión a internet."
- `IOException` (genérica) → "Error de conexión" / "No pudimos contactar con el servidor…".
- Tras publicar el estado, **relanza la excepción** para que el ViewModel apague su `Loading`.

`AppStatusManager` además tiene reglas de prioridad: un `FORCE_UPDATE` nunca es tapado por un `SERVER_ERROR`; un `SERVER_ERROR` activo no se limpia con un `OPERATIONAL`.

> **Excepción en Flutter:** una petición puede marcar `extra[kAllowServerErrorExtra] = true` (Retrofit:
> `@Extra({kAllowServerErrorExtra: true})`) para que su `5xx` no bloquee la app. Hoy solo la usa
> `PUT api/PaymentHistory/{id}/sync-status`, cuyo `502` significa "el banco no respondió, se reintenta" y no
> "servicio caído" (§3.10).

### 1.2 Cabeceras multi-tenant (`TenantHeadersInterceptor`)

La API Centralízate es multi-tenant (API `docs/api/multi-tenant.md`): `AppTenantMiddleware` resuelve la app y su
banco patrocinador con `X-App-Id`. Eso decide qué municipios devuelven `GetMunicipality` / `ByDepartamet_{id}`, qué
overrides de trámites aplica `GetInfoBy{id}` y en qué banco operan `POST api/Auth`, `POST api/User/CreateUser` y
`GET api/User/by-email`. Sin la cabecera la API cae a la app legacy de Bancolombia, sin ningún error visible.

`lib/core/api/tenant_headers_interceptor.dart` agrega, **solo** a peticiones hacia la API Centralízate
(producción o el servidor de pruebas, según `NetworkProvider.centralizacionApiUrl`; nunca a impuestos, PQRD,
autoliquidables ni Google):

| Cabecera | Valor |
|---|---|
| `X-App-Id` | `FlavorConfig.appIdentifier` (= `applicationId` del flavor; un test lo compara con Gradle). `municipios` → `com.tramites1cero1.centralizacion` (Bancolombia), `manizales` → `com.tramitesapp.manizales` (Santander). |
| `X-App-Version` | `AppInfo.version` |
| `X-Platform` | `android` / `ios`. En web y desktop no se envía: la API solo documenta esos dos valores y la cabecera es opcional. |

Va antes del `LogInterceptor`, así que las cabeceras salen en el log de debug. Un `X-App-Id` mal escrito o sin dar de
alta en el dashboard (pantalla Aplicaciones) tampoco da error: la app vería el catálogo de Bancolombia.

---

## 2. Base URLs (microservicios)

Definidas en `data/network/NetworkProvider.kt`:

| Constante | URL | Qué sirve |
|---|---|---|
| `CENTRALIZACION_API_URL` | `https://apicentralizate.1cero1.com/` | API principal: usuarios, auth, municipios, departamentos, recordatorios, historial de pagos, emails, fintech, personas invitadas. Es también la `baseUrl` del Retrofit principal en `NetworkModule`. |
| `TAX_API_URL` | `https://apidatamovil.1cero1.com/api/` | Impuestos (consulta + PDF) y pasarela de pago Bancolombia (`Pasarela/CrearTransaccion`). |
| `PQRD_API_URL` | `https://tramitesservices.1cero1.com/ApiTramites/api/` | PQRD (todos los listados + inserción) y solicitud de trámites (`Tramites/InsertarSolicitudTramite`). |
| `AUTOLIQUIDABLES_API_URL` | `https://autoliquidables.1cero1.com/` | Generales: departamentos y ciudades por departamento (usado en formularios PQRD/registro). |
| `GOOGLE_API_URL` | `https://people.googleapis.com/` | Google People API — perfil del usuario tras login con Google. |
| `GOOGLE_WEATHER_API_URL` | `https://weather.googleapis.com/` | Google Weather API (clima). **Actualmente comentado/inactivo** en `MunicipalityViewModel` — el código del clima está deshabilitado. |

> ⚠️ **iOS / App Transport Security:** todas las URLs productivas son HTTPS (bien). La app Android original tiene `usesCleartextTraffic="true"` y una base URL local comentada (`http://192.168.20.198:45600/`). En Flutter no se porta así: ver el servidor de pruebas abajo.

### Servidor de pruebas (`http://192.168.20.198:45600/`)

Los cambios de API (multi-tenant, rediseño del dashboard) viven solo aquí antes de pasar a producción.

- **Qué corre:** IIS con la API en la rama `develop` y la base de datos `DLLO3`. Producción
  (`https://apicentralizate.1cero1.com/`) sigue con `main`.
- **Solo reemplaza `CENTRALIZACION_API_URL`.** Impuestos, PQRD, autoliquidables y Google siguen en producción.
- **Solo en la LAN:** el dispositivo tiene que estar en la red de la oficina o en la VPN.
- **Cómo se usa:** `--dart-define=USE_DEV_SERVER=true`, solo en **Android debug** (`NetworkProvider`). Es HTTP
  plano, así que el permiso de cleartext vive en `android/app/src/debug/res/xml/network_security_config.xml`,
  limitado a esa IP. Release, profile, iOS y web siempre usan producción. La app muestra la marca **"API DEV"**.
- **Los datos son distintos a producción:** los ids de bancos y municipios no coinciden (p. ej. Santander es el
  banco 5 en pruebas y el 6 en producción; Manizales no existe en pruebas), y los municipios "… Test" (p. ej.
  Bello Test 74, Envigado Test 71) vienen sin `theme` ni `idShield`, así que su Home no carga.
  **No marques "Guardar selección"** con el servidor de pruebas: el id guardado apuntaría a otro municipio (o
  a ninguno) al volver a producción.
- **Pendiente:** un binding HTTPS en el IIS de pruebas permitiría usarlo también en iOS y quitar la excepción
  de cleartext.

> **Servicios con base URL distinta cargados vía `ApiFactory` directamente** (no por `AppModule`): `CourseService` y `VenueService` reciben el `ApiFactory` y construyen su servicio internamente (ver `CourseRepositoryImpl` / `VenueRepositoryImpl`). Revisar esos dos archivos para la base URL exacta de Cursos y Escenarios.

---

## 3. Inventario completo de endpoints

Agrupados por interfaz Retrofit (archivo `data/network/ApiService.kt` salvo donde se indique). Notación: `MÉTODO ruta` → tipo de respuesta.

### 3.1 AuthApiService — base `CENTRALIZACION_API_URL`
| Endpoint | Respuesta | Notas |
|---|---|---|
| `POST api/Auth` (body `LoginDTO`) | `ValidationResponseDTO` | Login nativo. Solo valida credenciales: **no emite token** (`sentencesError` = "Inicio de sesión exitoso"). Opera en el banco del `X-App-Id` (§1.2). Ver §5. |
| `POST api/User/CreateUser` (body `CreateUserDTO`) | `ValidationResponseDTO` | Registro. |
| `GET /api/User/by-email/?email=` | `UserDTO?` | Trae el usuario completo tras login. |
| `GET /api/DocumentType/GetDocumentTypes` | `List<DocumentTypeDTO>` | Tipos de documento. |
| `PUT /api/User/ChangeStatusUser/{id}/status/{status}` | `ValidationResponseDTO` | `Header Content-Length: 0`. Cambia `loginStatus` (sesión única). |
| `PUT api/User/update-password/{userId}` (body `UpdatePasswordRequestDto`) | `ValidationResponseDTO` | Cambio de contraseña autenticado. |
| `PUT api/User/updatePasswordByForget/{userId}` (body `UpdatePasswordByForgetDto`) | `ValidationResponseDTO` | Recuperación por olvido. |
| `PUT api/User/UpdateBasicInfo/{id}` (body `UpdateUserBasicInfoDTO`) | `ValidationResponseDTO` | Editar perfil. |
| `PUT api/User/{id}/update` (body `UpdateUserMunicipalityDTO`) | `ValidationResponseDTO` | **Actualiza el municipio del usuario** (clave para white-label, ver §7). |
| `DELETE api/User/Delete/{id}` | `ValidationResponseDTO` | Eliminar cuenta. |
| `GET api/user` | `List<UserDTO>` | Marcado en el código como sin uso claro. |

### 3.2 ApiCentralizateApps (interfaz duplicada/legacy, `domain/repository/ApiCentralizateApps.kt`)
Duplica `getUsers`, `createUser`, `loginUser`, `getUserByEmail`. **Punto de deuda técnica** — en Flutter consolidar en un solo servicio de auth/usuario.

### 3.3 MunicipalityApiService — base `CENTRALIZACION_API_URL`
| Endpoint | Respuesta | Notas |
|---|---|---|
| `GET /api/Municipality/GetInfoBy{id}` | `MunicipalityDTO` | **EL endpoint central de configuración.** Devuelve theme, escudo, módulos, trámites, fintech, privacidad, redes, etc. (Ver §4.1). |
| `GET /api/Municipality/ByDepartamet_{id}` | `List<Municipality>` | Municipios de un departamento (se filtran por `isActive`). |
| `GET /api/Municipality/GetMunicipality` | `ValidationResponseDTO` | Lista todos (los municipios vienen en `result: List<MunicipalitiesDTO>`). |

### 3.4 DepartmentApiService — base `CENTRALIZACION_API_URL`
| `GET /api/Department` | `List<Department>` | Departamentos para el selector. |

### 3.5 GeneralesApiService — base `AUTOLIQUIDABLES_API_URL`
| `GET api/Generales/GetDepartamentos` | `List<Departamento>` | (PQRD dto). |
| `GET api/Generales/CiudadesXDepartamento?id_Departamento=` | `List<Ciudad>` | (PQRD dto). |

### 3.6 TaxApiService — base `TAX_API_URL`
| `POST ImpuestoEntidad/GetImpuestos` (body `TaxQueryRequestDTO`) | `TaxQueryResponseDTO` | Consulta de impuestos. |
| `POST ImpuestoEntidad/GetDownloadPDF` (body `TaxQueryRequestDTO`) | `String` | URL/base64 del PDF de factura. |
| `GET @Url fileUrl` | `ResponseBody` | Descarga directa de archivo por URL absoluta. |

### 3.7 PaymentApiService — base `TAX_API_URL`
| `POST Pasarela/CrearTransaccion` (body `BancolombiaGatewayRequestDTO`) | `BancolombiaGatewayResponseDTO` | Pasarela de pago. |

### 3.8 FintechPayments — base `CENTRALIZACION_API_URL`
| `POST api/Fintech/transactionFintech/{id}` (body `FintechTransactionRequestDTO`) | `FintechTransactionResponseDTO` | Transacción fintech por municipio. |

### 3.9 StatusOfPayments — base ligada a pagos (revisar; usa `Login/authenticate`)
| `POST Login/authenticate` (body `LoginRequest`) | `String` (token) | **Credenciales hardcodeadas** en `LoginRequest` (usuario/clave por defecto en el código). Riesgo de seguridad a revisar en migración. |
| `GET transaction?CodigoEntidad=&Factura=&IDImpuesto=` (Header `Authorization`) | `StatusTransactionDto` | Estado de transacción. |

### 3.10 PaymentHistory — base `CENTRALIZACION_API_URL`
| `GET api/PaymentHistory/User/{id}` | `PaymentHistoryListDTO` | Historial de pagos del usuario. |
| `PUT api/PaymentHistory/{id}/sync-status` | `ValidationResponseDTO` | Sincroniza el estado de un pago contra la pasarela. Aquí el HTTP **sí** coincide con `codeStatus`: 200 (sincronizado o reprogramado), 400/404 (no existe), **502** (el banco no respondió; se reprograma solo) y 500. Marcado para que su 5xx no bloquee la app (§1.1). ⚠️ El Kotlin declaraba `{id}/sync-status` sin el prefijo del controlador: esa ruta no existe, así que la sincronización a demanda nunca funcionó y solo el job del servidor actualizaba estados. Corregido en Flutter. |
| `DELETE api/PaymentHistory/User/{idUser}/History/{idHistory}` | `ValidationResponseDTO` | Borra un pago del historial. |
| `POST api/PaymentHistory/` (body `CreatePaymentHistory`) | `ValidationResponseDTO` | Crea registro de pago. |

### 3.11 RemindersApiService — base `CENTRALIZACION_API_URL`
| `GET api/Reminders/Get/Reminders/ByUser/{userId}` | `List<RemindersByUserDto>` | Recordatorios del usuario. |
| `POST /api/Reminders/Create/Reminders` (body `CreateReminderDto`) | `RemindersByUserDto` | Crear recordatorio. |
| `DELETE /api/Reminders/Delete/{id}` | `ValidationResponseDTO` | Eliminar. |

### 3.12 SendEmailsService — base `CENTRALIZACION_API_URL`
| `POST api/Email/SendEmail` (body `EmailDto`) | `ValidationResponseDTO` | Email genérico (soporte/ayuda). |
| `GET api/Email/SendEmail/ValidationCode?To=` | `ValidationResponseExtraDto` | Código de verificación por email. |
| ~~`POST api/Email/SendEmail/Reservations`~~ | — | **No existe en la API** (el `EmailController` solo tiene `SendEmail`, `SendEmail/ValidationCode`, `SendEmail/Panic` y `SendEmail/reminders`). El correo de reserva lo envía el servidor desde `POST api/reservations`. Eliminado del cliente Flutter junto con `EmailDtoReservations`. |
| `POST api/Email/SendEmail/Panic` (body `PanicEmailDto`) | `ValidationResponseDTO` | Botón de pánico. |

### 3.13 PeopleInvitatedService — base `CENTRALIZACION_API_URL`
| `POST api/PeopleInvitated/Create` (body `PeopleInvitated`) | `ValidationResponseDTO` | Personas invitadas. |

### 3.14 ProcedureApplicationApi — base `PQRD_API_URL`
| `POST Tramites/InsertarSolicitudTramite` (body `ProcedureApplicationRequest`) | `Response<ProcedureApplicationResponse>` | Solicitud de trámite. |

### 3.15 TramitesApiService — base `CENTRALIZACION_API_URL`
| ~~`GET api/municipios/{id}/tramites`~~ | — | **No existe en la API.** Los trámites vienen embebidos en `GetInfoBy{id}`. Eliminado del cliente Flutter (`TramitesApiService` y su provider). |

### 3.16 PqrdApiService — base `PQRD_API_URL`
Inserción:
| `POST PQRD/InsertPQRDAnonima` (body `PqrdAnonimaPost`) | `ResponsePQRD` |
| `POST PQRD/InsertPQRDIdentificacion` (body `PqrdIdentificacionPost`) | `ResponsePQRD` |

Listados (todos reciben `?CodigoEntidad=` y devuelven `List<…>`):
`SecretariaEntidad/ListSecretariaEntidad`, `PQRD/ListAsuntoInteres`, `PQRD/ListClasificacionSolicitud`, `PQRD/ListTipoSolicitante`, `PQRD/ListAtencionPreferencial`, `PQRD/ListMedioRespuesta`, `PQRD/ListTipoDocumento`, `PQRD/GetListGrupoInteresPQRD`, `PQRD/ListDiscapacidadPQRD`, `PQRD/GetListGrupoEtnicoPQRD`, `PQRD/ListGeneroPQRD`, `PQRD/ListRangoEdadPQRD`, `PQRD/ListActividadEconomicaPQRD`, `PQRD/ListNivelEstractoPQRD`, `PQRD/ListNivelSisbenPQRD`, `PQRD/ListEscolaridadPQRD`, `PQRD/ListVulnerabilidadPQRD`.

> **Patrón clave:** casi todos los servicios "por municipio" se parametrizan con **`CodigoEntidad`** (string, = `entityCode` del `MunicipalityDTO`) o con el **`id`** del municipio. Este identificador es el eje de todo el comportamiento multi-municipio. (Ver §7).

### 3.17 GoogleApiService — base `GOOGLE_API_URL`
| `GET v1/people/me?personFields=names,emailAddresses,phoneNumbers,birthdays,addresses` (Header `Authorization`) | `PeopleResponse` | Perfil de Google para prellenar registro. |

### 3.18 WeatherApiService — base `GOOGLE_WEATHER_API_URL`
Clima. **Actualmente deshabilitado** (código comentado en `MunicipalityViewModel`). Decidir en migración si se reactiva.

---

## 4. Contratos de datos (DTOs)

### 4.1 ⭐ MunicipalityDTO — objeto central de configuración
Respuesta de `GET /api/Municipality/GetInfoBy{id}`. Define **toda la identidad y capacidades del municipio**:

> **Nulabilidad (Flutter):** la API declara casi todo nullable (`GetMunicipalitysDto.cs`) y el wizard del dashboard
> ya crea municipios con campos vacíos (sin credenciales Fintech, banco, tema…). En Flutter, `MunicipalityDTO` y todo
> lo que embebe (más `Municipality` de `ByDepartamet` y `MunicipalitiesDTO` de `GetMunicipality`) leen `null` como
> valor vacío: strings `''`, listas `[]`, `isActive` `false` y objetos anidados vacíos. Sin `theme` quedan los grises
> de `parseColor`; sin `idShield`, el header muestra el ícono de respaldo. Con datos completos nada cambia.
> **`phone` es `String?`** (en la API es `string?` desde 2025-11; el `Int?` del Kotlin rompía el parseo); se acepta
> también un número.

```kotlin
data class MunicipalityDTO(
    val courses: List<CourseX>,                          // módulo Cursos (si no vacío → se muestra)
    val department: Department,
    val domain: String,
    val entityCode: String,                              // ⭐ CodigoEntidad — eje multi-municipio
    val id: Int,
    val isActive: Boolean,
    val municipalityProcedures: List<MunicipalityProcedure>, // trámites disponibles
    val municipalitySocialMedia: List<MunicipalitySocialMedia>, // redes sociales
    val name: String,
    val passwordFintech: String,                         // credencial fintech (sensible)
    val queryFields: List<QueryField>,                   // campos de consulta de impuestos
    val sportsFacilities: List<SportsFacility>,          // módulo Escenarios (si no vacío → se muestra)
    val theme: Theme,                                    // ⭐ COLORES (hex string)
    val userFintech: String,                             // credencial fintech (sensible)
    val bank: BankDTO,
    val idShield: ShieldDTO,                             // ⭐ ESCUDO (url) + nombre municipio
    val dataPrivacy: String?,                            // URL política de privacidad
    val dataProcessingPrivacy: String?,                  // URL tratamiento de datos
    val newsByMunicipalities: List<NewsByMunicipality>,  // URL de noticias
    val latitude: String?, val longitude: String?,       // para clima (deshabilitado)
    val emailMunicipalities: String?,                    // email de contacto del municipio
    val emailPanic: String?,                             // email del botón de pánico
    val phone: Int?,
)
```

**`Theme` (colores, todos hex string tipo `"0xFFRRGGBB"` u `"FFRRGGBB"`):**
```kotlin
data class Theme(
    val backGroundColor: String,
    val onPrimaryColorDark: String,
    val onPrimaryColorLight: String,
    val primaryColor: String,
    val secondaryColor: String,
    val secondaryColorBlack: String,
)
```
Se parsean con `parseColor()` (quita `0x`, espera 8 chars ARGB; fallback gris). En Flutter: `Color(int.parse(hex, radix:16))` con la misma defensa.

**`ShieldDTO`:**
```kotlin
data class ShieldDTO(
    @SerializedName("nameOfMunicipality") val municipalityName: String,
    @SerializedName("url") val url: String,   // imagen del escudo (se carga con Coil → cached_network_image)
)
```

**Decisión de módulos (regla actual, en `MunicipalityDTO.toDomainModel()`):**
- Cursos se muestra si `courses.firstOrNull()` existe y `isActive`.
- Escenarios ("Reserva de espacios") se muestra si `sportsFacilities.firstOrNull()` existe y `isActive`.
- Cada trámite se muestra según `municipalityProcedures[].procedures.id` mapeado a íconos/acciones (ver FRONTEND §trámites).
- → **No hay feature-flags en el cliente: el backend decide qué módulos llegan.** Replicar esta regla tal cual.

### 4.2 ValidationResponseDTO — envoltura de respuesta estándar
```kotlin
data class ValidationResponseDTO(
    val codeStatus: Int = 0,
    val booleanStatus: Boolean = false,        // éxito/fallo
    val sentencesError: String = "",           // mensaje (en login exitoso: "Inicio de sesión exitoso", NO un token)
    val result: List<MunicipalitiesDTO>? = null // payload en algunos endpoints (lista de municipios)
)
```
**Convención crítica:** el éxito se evalúa por `booleanStatus`, no por el HTTP code. `sentencesError` no siempre es un error: en éxito trae un mensaje informativo. ⚠️ **`POST api/Auth` no emite token** (API `docs/api/auth.md`: la API no tiene autenticación); en login exitoso `sentencesError` es solo "Inicio de sesión exitoso". El Kotlin lo guardaba como `auth_token` creyendo que era un token.

### 4.3 UserDTO — usuario (persistido en DataStore como JSON)
```kotlin
data class UserDTO(
    val id: Int, val address: String,
    val documentType: DocumentTypeDTO, val documentTypeId: Int,
    val email: String, val firstName: String, val lastName: String,
    val loginStatus: Boolean,                  // sesión única activa
    val middleName: String?, val nationalId: String, val password: String,
    val phoneNumber: String, val secondLastName: String?, val birthDate: String,
    val fixedMunicipality: Int? = 0,           // ⭐ municipio FIJO del usuario (white-label)
    val lastMunicipality: Int? = 0             // ⭐ último municipio seleccionado (multi)
)
```
> **`fixedMunicipality` vs `lastMunicipality`** son el gancho de datos para el modelo white-label. Ver §7.

### 4.4 CreateUserDTO — registro
```kotlin
data class CreateUserDTO(
    val id: Int = 0, val firstName: String = "", val middleName: String? = null,
    val lastName: String = "", val secondLastName: String? = null,
    val documentTypeId: Int = 0, val nationalId: String = "", val email: String = "",
    val password: String = "", val address: String = "", val phoneNumber: String = "",
    val birthDate: String = "", val loginStatus: Int? = null,
    val fixedMunicipality: Int? = 0, val lastMunicipality: Int? = 0
)
```

### 4.5 Otros DTOs (catálogo)
`AppGlobalConfigDTO` (Remote Config, ver §6), `BankDTO`, `CourseDTO`/`CourseX`, `VenueDTO`, `SportsFacility`, `MunicipalityProcedure`/`Procedures`, `QueryField`, `MunicipalitySocialMedia`/`SocialMediaType`, `DocumentTypeDTO`, `LoginDTO`, `EmailDTO`(+ Panic), `PaymentHistoryDTO`/`PaymentHistoryListDTO`, `StatusTransactionDto`, `ProcedureApplicationRequest`/`Response`, `TaxDTO`/`TaxQueryRequestDTO`/`TaxQueryResponseDTO`, `BancolombiaGatewayRequestDTO`/`ResponseDTO`, `FintechTransactionRequestDTO`/`ResponseDTO`, `UpdatePasswordRequestDto`, `UpdatePasswordByForgetDto`, `UpdateUserBasicInfoDTO`, `UpdateUserMunicipalityDTO`, `RemindersByUserDto`/`CreateRemindersByUserDto`, `PeopleInvitated`/`PeopleResponse`, `WelcomeCarouselImageDTO`, `TourismContributionDTO`, `GoogleWeatherDTO`, `NewsByMunicipality`, `ValidationResponseExtraDto`.

**PQRD dtos** (paquete `data/model/pqrddto/`): `PqrdAnonimaPost`, `PqrdIdentificacionPost`, `ResponsePQRD`, `Secretaria`, `AsuntoInteres`, `ClasificacionSolicitud`, `TipoSolicitante`, `AtencionPreferencial`, `MedioRespuesta`, `TipoDocumento`, `GrupoInteresPQRD`, `DiscapacidadPQRD`, `GrupoEtnicoPQRD`, `GeneroPQRD`, `RangoEdadPQRD`, `ActividadEconomicaPQRD`, `NivelEstratoPQRD`, `NivelSisbenPQRD`, `EscolaridadPQRD`, `VulnerabilidadPQRD`, `Ciudadano`, `Documentos`, `Ciudad`, `Departamento`.

> Para la migración, cada DTO se reescribe como clase Dart con `json_serializable`/`freezed`. Mantener los nombres de campo JSON (`@SerializedName`) exactos para no romper contratos.

---

## 5. Autenticación — DOS caminos paralelos

### 5.1 Login nativo (correo + contraseña) — NO usa Firebase
Flujo (`AuthViewModel.authenticate()` → `AuthRepositoryImpl`):
1. Validación local: email con `Patterns.EMAIL_ADDRESS`, password ≥ 8 chars.
2. `POST api/Auth` con `LoginDTO(email, password)` → `ValidationResponseDTO`.
3. Si `booleanStatus == true`: `GET /api/User/by-email/?email=` → `UserDTO`.
4. Si `user.loginStatus == true`: se guarda sesión (`saveUserSession` → DataStore JSON) y `loginResult.sentencesError` vía `saveAuthToken`. **No es un token** (la API no emite ninguno): es el mensaje "Inicio de sesión exitoso". Flutter conserva ese guardado por paridad, pero nada lo lee.
5. Se incrementa contador para In-App Review (Google Play Review API).

### 5.2 Login con Google — ÚNICO uso de Firebase Auth
Flujo (`LoginOptionsViewModel`):
1. `GoogleSignInOptions` con `requestIdToken(default_web_client_id)` + `requestEmail()`.
2. Tras el intent de Google: `GoogleSignIn.getSignedInAccountFromIntent` → `idToken`.
3. `GoogleAuthProvider.getCredential(idToken)` → `FirebaseAuth.signInWithCredential` (timeouts de 5s con `withTimeout`).
4. Si `isNewUser` → busca por email en la API propia; si no existe, prellena `CreateUserDTO` con datos de Google (`fetchGoogleProfile`) y navega a registro.
5. Si usuario existente → `getUserInformationByEmail` → marca `loginStatus=true` → `saveUserSession` → entra.
6. Fallbacks a registro en cualquier error/timeout.

> **Implicación Flutter:** usar `firebase_auth` + `google_sign_in` SOLO para el botón de Google. El login nativo es un POST normal con `dio`. La sesión "real" del usuario vive en la API propia + DataStore, no en Firebase. En iOS, Google Sign-In requiere configurar el `REVERSED_CLIENT_ID` en `Info.plist` y el `GoogleService-Info.plist`.

### 5.3 Sesión y "sesión única"
- La sesión persiste como JSON de `UserDTO` en DataStore (`user_data`). `auth_token` guarda el mensaje del login, no un token (§5.1).
- `loginStatus` + el endpoint `ChangeStatusUser/{id}/status/{status}` implementan sesión única (al entrar en un dispositivo se invalida en otro). `LoginOptionsViewModel.signOut()` se llama en `onCreate` de `MainActivity`.
- `MainActivity` setea `Firebase.crashlytics.setUserId(user.id)` cuando hay sesión.

---

## 6. Firebase — uso REAL (confirmado, no asumir de más)

| Servicio | Uso real | NO se usa para |
|---|---|---|
| **Remote Config** | (1) `welcome_carousel_images` → imágenes de anuncios del carrusel de bienvenida. (2) `app_status_config` → estado global de la app (operational/maintenance/force_update) + versión mínima. (3) `send_to_welcome` (Boolean) → decide a dónde enviar al usuario al iniciar. (4) `tourism_tax_rates` → tarifas de aporte a turismo. | **NO** define colores, escudo ni módulos (eso es del backend, §4.1). |
| **Cloud Messaging (FCM)** | Solo notificaciones push. Suscripción **por tópico de municipio**: `theme_<NombreMunicipioNormalizado>` (ver §7). Dos canales: `firebase_notifications_channel` (default) y `firebase_campaigns_channel` (campañas con URL). | — |
| **Analytics** | Registro de eventos para estadísticas de uso y clics por módulo. **El equipo considera que esto puede reimplementarse mejor** → tratar como oportunidad de rediseño en Flutter, no copiar 1:1. | — |
| **Crashlytics** | Reportes de crash. Se asocia `setUserId`. | — |
| **Auth** | Solo para login con Google (§5.2). | Login nativo NO. |
| **Performance / In-App Messaging** | Presentes en Gradle (perf logcat activado). Validar si realmente aportan o se retiran. | — |

### 6.1 Remote Config — claves y parsing
Configuración: `minimumFetchIntervalInSeconds = 120` (comentario dice "1 hora" pero el valor real es 120s), `setDefaultsAsync(R.xml.remote_config_defaults)`.

- `welcome_carousel_images` → JSON → `CarouselConfigDTO { images: [{imageUrl, clickUrl}] }`.
- `tourism_tax_rates` → JSON → `TourismTaxConfigDTO`.
- `app_status_config` → JSON → `AppGlobalConfigDTO`:
  ```kotlin
  data class AppGlobalConfigDTO(
      val status: String = "operational",   // operational | maintenance | server_error | force_update
      val title: String = "",
      val message: String = "",
      val dismissible: Boolean = true,       // false = bloqueo total (pantalla roja)
      val minVersionCode: Int = 0            // fuerza actualización si VERSION_CODE < min
  )
  ```
  Regla de oro: primero compara `BuildConfig.VERSION_CODE < minVersionCode` → `FORCE_UPDATE` bloqueante. Luego `status == "maintenance"` → bloqueo según `dismissible`.
- `send_to_welcome` (Boolean) → `shouldSendToWelcome()` decide el `startDestination` (§7.2).

> **Flutter:** `firebase_remote_config`. Mantener exactamente las mismas keys (`welcome_carousel_images`, `app_status_config`, `send_to_welcome`, `tourism_tax_rates`) porque las define el mismo backoffice de Firebase, compartido entre apps. Cada flavor/app individual usa **su propio proyecto Firebase**, así que estas keys deben existir en cada proyecto.

> **Solo Flutter — `tutorial_config`** (tutorial de primer uso, 2026-10-22): JSON con el interruptor y los
> textos de las tarjetas, `{"enabled": true, "cards": {"1": {"title": "…", "body": "…"}, …}}`. Si la key
> no existe, la app usa `{"enabled":true}` y sus textos. Claves de `cards`: `1`, `2A`, `2B`, `3A`, `3B`,
> `4`, `4_sin_pqrsdf`, `5`, `6A`, `6B`, `7`; `{alcaldia}` se reemplaza por «Alcaldía de {nombre}».
> Código: `lib/features/tutorial/domain/tutorial_config.dart`.
>
> **Solo Flutter — `tutorial_videos`** (videos tutoriales, 2026-10-22): `{"enabled": true, "videos": [{"id":
> "pagos", "title": "…", "youtubeId": "8K_o2pC19qY", "places": ["welcome", "ayuda"], "requires": []}, …]}`.
> Si no viene `videos`, la app usa sus dos videos por defecto; si viene, reemplaza la lista completa.
> `places`: `welcome` / `ayuda`. `requires` (opcional): tipos de trámite del API (`COURSES`, `VENUES`,
> `PQRSDF`…); el video sale solo si la alcaldía tiene alguno activo, y nunca en Bienvenida.
> Código: `lib/features/tutorial/domain/tutorial_videos.dart`.

---

## 7. Mecánica multi-municipio / white-label (lado backend/datos)

Este es el corazón de "una base, N apps". **Hoy el backend ya soporta todo esto**; la app solo cambia qué municipio pide.

### 7.1 El identificador del municipio manda
- `MunicipalityDTO.id` (Int) y `MunicipalityDTO.entityCode` (String, "CodigoEntidad") parametrizan TODO: trámites, PQRD (todos los listados), impuestos, pagos, fintech, emails.
- `GET /api/Municipality/GetInfoBy{id}` con ese `id` devuelve la config completa (colores, escudo, módulos). → **Para una app individual basta con fijar ese `id` y no mostrar el selector.**

### 7.2 Cómo se decide el municipio hoy (Trami App Municipios)
`MainActivityViewModel` combina 3 fuentes y calcula `startDestination`:
```
sendToWelcome (Remote Config)         → INITIAL_NAV_GRAPH (welcome + selector)
else si ubicacionPref.guardado=true   → ALCALDIAS_FLOW_ROOT (entra directo al municipio guardado)
else                                  → INITIAL_NAV_GRAPH
```
La "ubicación guardada" vive en DataStore (`getSavedUbication()`): `departmentId`, `municipalityId`, `municipio` (nombre), `guardado` (Boolean). Se setea en `SelectMunScreen` (`saveUbicationPreferences`).

### 7.3 Hooks de white-label que ya existen
- **`UserDTO.fixedMunicipality`**: municipio fijo asignado al usuario (ideal para apps individuales / usuarios cuyo municipio no cambia).
- **`UserDTO.lastMunicipality`**: último municipio elegido (modelo multi, app Municipios).
- **`PUT api/User/{id}/update`** (`UpdateUserMunicipalityDTO`): actualiza el municipio del usuario en backend y refresca DataStore localmente (`AuthRepositoryImpl.updateDynamicMunicipality`).
- **DataStore `clearCurrentMunicipality()`**: limpia la selección.

### 7.4 Modelo recomendado para apps individuales en Flutter
Para **Trami App Manizales** (app individual):
1. El **flavor** fija un `municipioId` constante (build-time) y `showSelector = false`.
2. La app arranca llamando directo a `GetInfoBy{municipioId_fijo}` → recibe colores/escudo/módulos de Manizales desde el backend.
3. No se muestra `WelcomeScreen`/`SelectMunScreen`.
4. Todo lo demás (trámites, PQRD, pagos) usa el `entityCode` de Manizales que vino en el DTO.
5. Push: suscripción al tópico `theme_Manizales` (FCM) — ojo, en un proyecto Firebase propio de Manizales.

→ **Cero cambios de backend necesarios para esto.** El backend ya entrega config por `id`. Lo único "nuevo" es que el cliente fije el `id` en vez de pedirlo al usuario.

### 7.5 Tópico FCM por municipio
`MunicipalityViewModel.formatTopicName()`: normaliza el nombre (NFD, quita acentos y no-alfanuméricos, espacios→`_`) y antepone `theme_`. Ej: "Manizales" → `theme_Manizales`. La suscripción es **acumulativa** (no desuscribe de anteriores) en la app Municipios. En una app individual debería suscribirse solo a su municipio.

---

## 8. Caché y rendimiento (comportamiento a preservar)
- `MunicipalityRepositoryImpl` cachea `MunicipalityModel` en memoria (`ConcurrentHashMap<Int, MunicipalityModel>`) → no re-pide `GetInfoBy` si ya se cargó ese `id` en la sesión.
- `MunicipalityViewModel` cachea clima por `municipalityId` (clima hoy deshabilitado).
- Timeouts de red: 40s en todas las operaciones.

---

## 9. Riesgos / deuda técnica del backend a tener presente en la migración
1. **Credenciales hardcodeadas** en `StatusOfPayments.LoginRequest` (usuario/clave por defecto en el código fuente). Revisar antes de portar.
2. **Credenciales fintech** (`userFintech`, `passwordFintech`) viajan dentro del `MunicipalityDTO` al cliente. Evaluar exposición.
3. **Interfaces de auth duplicadas** (`AuthApiService` vs `ApiCentralizateApps`). Consolidar.
4. **`sentencesError` multiuso**: es un mensaje, nunca un token (`POST api/Auth` no emite ninguno; la API no tiene autenticación).
5. **6 base URLs** sin versionado de API (`/v1`). Cambios de backend para futuras alcaldías podrían introducir versioning.
6. **Clima deshabilitado** pero el código sigue presente. Decidir.
7. **Analytics** señalado por el equipo como reimplementable. No copiar la instrumentación 1:1.
8. **iOS/ATS:** confirmar que el 100% de endpoints productivos son HTTPS (al portar, eliminar la base URL local HTTP comentada).

---

*Generado a partir del código de la rama `main` (Trami App Municipios, Android/Kotlin). Versión base: 1.4.4 (versionCode 46). Backend a consumir sin cambios en la migración a Flutter.*
