# Trami App — Documento FRONTEND (comportamiento de la app)

> **Propósito.** Describe cómo se comporta la app actual (Trami App Municipios, Android/Kotlin + Jetpack Compose) con respecto a lo que recibe del backend: arranque, navegación, theming dinámico, pantallas/módulos, estado global, notificaciones y la mecánica white-label en el lado del cliente. Pensado para alimentar agentes de IA en la **migración a Flutter desde cero**.
>
> Documento hermano: `MIGRACION_FLUTTER_BACKEND.md` (servicios que consume).
>
> **Decisión confirmada:** proyecto Flutter nuevo desde cero, Android actual se mantiene en paralelo. Prioridad: **Trami App Manizales** (iOS + Android), luego escalar a apps individuales por municipio y, a largo plazo, Trami App Municipios en iOS.

---

## 0. Stack actual y equivalentes Flutter

| Capa | Android actual | Equivalente Flutter sugerido |
|---|---|---|
| Lenguaje / UI | Kotlin + Jetpack Compose | Dart + Flutter |
| DI | Hilt (`@Module`, `@Provides`, `@HiltViewModel`) | Riverpod + get_it |
| Estado | `ViewModel` + `StateFlow`/`MutableStateFlow` + `collectAsStateWithLifecycle` | Riverpod (`AsyncNotifier`/`StateNotifier`) |
| Navegación | Navigation Compose (NavHost + grafos anidados) | go_router (rutas anidadas) |
| HTTP | Retrofit + OkHttp + Gson | dio + retrofit_dart + json_serializable |
| Persistencia local | DataStore Preferences (+ algo de SharedPreferences) | shared_preferences / Hive |
| Imágenes remotas | Coil + Glide | cached_network_image |
| Cámara / escaneo | ML Kit Barcode + CameraX | mobile_scanner |
| WebView / Tabs | AndroidX WebKit + Chrome Custom Tabs | flutter_inappwebview / url_launcher |
| Push | FCM | firebase_messaging |
| Crash/Analytics/RC | Firebase Crashlytics / Analytics / Remote Config | firebase_crashlytics / firebase_analytics / firebase_remote_config |
| In-App Update | Google Play Core (IMMEDIATE) | upgrader (Android); en iOS no aplica, usar revisión App Store |
| In-App Review | Google Play Review API | in_app_review |
| Descargas PDF | DownloadManager + DownloadCompletedReceiver (BroadcastReceiver) | dio (stream a archivo) + open_filex |

---

## 1. Arranque de la app (orden exacto)

`MainActivity.onCreate` (Application = `MyApp`, `@HiltAndroidApp`):
1. `WindowCompat.setDecorFitsSystemWindows(false)` → edge-to-edge.
2. Pide permiso `POST_NOTIFICATIONS` (Android 13+).
3. Obtiene el token FCM (log).
4. `viewModel.checkRemoteConfig()` → `RemoteConfigRepository.checkAppStatus()` (estado global app).
5. Observa `authViewModel.user` → setea `Crashlytics.setUserId`.
6. `loginOptionsViewModel.signOut()` (limpia sesión Google/Firebase residual al arrancar).
7. `AppUpdateManager` → `checkForAppUpdate()` (actualización IMMEDIATE de Play).
8. `setContent { … }` con la jerarquía de UI por prioridad (ver §3).
9. `MyApp.onCreate` crea el canal de notificaciones `reminders_channel`.

> **Flutter:** este orden se traduce a un `main()` + `bootstrap` (init Firebase, Remote Config fetch, permisos) y un widget raíz que decide la UI según estado global. In-App Update IMMEDIATE no tiene equivalente iOS — en iOS se confía en la actualización de la App Store; en Android puede usarse `upgrader` o el flujo nativo.

### 1.1 Decisión de pantalla inicial (`startDestination`)
`MainActivityViewModel` combina 3 flujos (`combine`): tema oscuro (DataStore), ubicación guardada (DataStore) y `shouldSendToWelcome()` (Remote Config). Resultado:
```
sendToWelcome == true            → INITIAL_NAV_GRAPH  (WelcomeScreen → selector municipio)
else si ubicacion.guardado       → ALCALDIAS_FLOW_ROOT (entra directo al municipio guardado)
else                             → INITIAL_NAV_GRAPH
```
Mientras decide, `state.isLoading` muestra un `CircularProgressIndicator` sobre `primarycolor`.

> **Para Trami App Manizales (individual):** este árbol se simplifica — el municipio está fijo por flavor, así que el `startDestination` siempre entra directo al home del municipio (equivalente a `ALCALDIAS_FLOW_ROOT`) sin pasar por Welcome ni selector.

---

## 2. Navegación — grafos anidados

`AppNavHost` (`AppNavGraph.kt`) define un `NavHost` con transiciones slide horizontal (tween 300ms) y 3 grafos:

```
AppNavHost(startDestination)
├── initialNavGraph         (INITIAL_NAV_GRAPH)
│     ├── WelcomeScreen      ← carrusel/anuncios, theming InicialTheme
│     └── SelectMunScreen/{departmentId}  ← selector de municipio
│
├── alcaldiasFlowGraph      (ALCALDIAS_FLOW_ROOT)  ⭐ orquestador del municipio
│     ├── mainNavGraph       (MAIN_NAV_GRAPH = startDestination interno)
│     ├── paymentsNavGraph
│     ├── pqrdsNavGraph
│     ├── certificatesNavGraph
│     ├── psvNavGraph
│     ├── checkingPaymentNavGraph
│     └── PublicServiceNavGraph
│
└── signUpNavGraph          (registro 3 pasos)
```

### 2.1 Patrón clave: ViewModel compartido a nivel de grafo
`alcaldiasFlowGraph` actúa como **orquestador**: el `MunicipalityViewModel` se instancia a nivel del grafo padre (`AppRoutes.ALCALDIAS_FLOW_ROOT`) y se comparte entre todas las pantallas hijas vía `hiltViewModel(parentEntry)`. Así, la config del municipio (colores, trámites) se carga una vez y todas las sub-pantallas la consumen.

`AlcaldiasStateWrapper` envuelve el contenido del grafo y, según `MunicipalityUiState`:
- `Success` → aplica `AlcaldiasTheme(design = state.data.design)` (theming dinámico) y muestra el contenido.
- `Error` → `ErrorMuncipalityScreen`.
- `Loading`/`Empty` → `AlcaldiasTheme(design = Design())` (defaults) + contenido.

> **Flutter:** go_router con `ShellRoute` para el "alcaldiasFlow" + un provider Riverpod scoped que carga el `MunicipalityModel` una vez y un wrapper que aplica el `ThemeData` dinámico (equivalente a `AlcaldiasStateWrapper`).

### 2.2 Rutas (de `AppRoutes.kt`)
Rutas con parámetros relevantes (notar cuántos datos viajan por la ruta — en Flutter conviene pasar objetos/extra en vez de strings largos):
- `SELECT_MUN_SCREEN/{departmentId}`
- `COURSES_SCREEN = CoursesScreen/{municipalityId}/{courseId}/{dataPolicyUrl}/{privacyPolicyUrl}/{emailMunicipalities}`
- `VENUES_SCREEN = VenuesScreen/{municipalityId}/{venueId}/{dataPolicyUrl}/{privacyPolicyUrl}/{emailMunicipalities}`
- `TAX_QUERY_SCREEN = TaxQueryScreen/{entityCode}/{queryFieldsJson}/{taxId}/{title}/{dataPolicyUrl}/{privacyPolicyUrl}`
- `PSV_SCREEN = psv_screen/{taxId}/{taxName}`
- `PAYMENT_PROCESSING_SCREEN = PaymentProcessingScreen/{paymentUrl}` (URL-encoded de la pasarela)
- `CERTIFICATES_STEP1 = CertificatesStep1` (+ `/{entityCode}/{procedureId}/{integrationType}`)
- `HELP_SCREEN_ROUTE = help_screen/{municipio}`
- `SIGNUP_NAV_GRAPH_ROUTE = signup_graph?origin={origin}`

---

## 3. Estado global de la UI (jerarquía de prioridad)

Dentro de `setContent`, el orden de decisión (excluyente) es:
1. **SERVER_ERROR bloqueante** (y no estamos en pantalla inicial) → `AppErrorStatusScreen` con botón de reintento (cuenta reintentos vía `RETRY_COUNT_KEY` en el intent, reinicia la Activity).
2. **Sin internet** (`ConnectivityObserver`, con debounce de 3s) → `NoConnectionDialog` (se cierra solo al volver la conexión).
3. **Loading** → spinner sobre `primarycolor`.
4. **Normal** → `AppNavHost`.

`AppStatusManager` (singleton, `StateFlow<AppStatus>`) es la fuente de verdad del estado global; lo alimentan tanto `GlobalErrorInterceptor` (red) como `RemoteConfigRepository.checkAppStatus()` (mantenimiento/force update). Tipos: `OPERATIONAL | MAINTENANCE | FORCE_UPDATE | SERVER_ERROR`.

`ConnectivityObserver` (`NetworkConnectivityObserver`) emite `Status` (Available/…); el diálogo aparece tras 3s sin red para evitar molestar con micro-cortes.

> **Flutter:** un `appStatusProvider` (Riverpod) equivalente a `AppStatusManager`, alimentado por el interceptor `dio` y el check de Remote Config. Un widget raíz que renderiza por prioridad igual que arriba. `connectivity_plus` para el observer.

---

## 4. Theming dinámico (lo recibe del backend)

⭐ **Punto central del white-label visual.** Los colores y el escudo NO están en el código: llegan en `MunicipalityDTO.theme` (hex strings) y `idShield.url`, y se aplican en runtime.

### 4.1 Flujo de color
1. `MunicipalityDTO.theme` (6 colores hex) → `Theme.toDesignModel()` → `Design` (objeto con `androidx.compose.ui.graphics.Color`).
2. `parseColor(hex)`: quita prefijo `0x`, exige 8 caracteres ARGB, `Color(hex.toULong(16))`; fallback gris/negro/blanco según el campo.
3. `AlcaldiasTheme(design, darkTheme)` parte de `BrandLightColorScheme`/`BrandDarkColorScheme` y **sobrescribe** `primary`, `onPrimary`, `secondary`, `onSecondary`, `error` con los colores del municipio.
4. Status bar y navigation bar transparentes; iconos claros/oscuros según `darkTheme`.

`Design` (defaults cuando aún no hay datos):
```kotlin
data class Design(
    val NombreAlcaldia: String = "",
    val escudoUrl: String = "",
    val primaryColor: Color = primarycolor,
    val secondaryColor: Color = primarycolor,
    val secondaryColorDark: Color = Color.White,
    val onPrimaryColorLight: Color = Color.White,
    val onPrimaryColorDark: Color = Color.White
)
```

### 4.2 Otros temas presentes
- `InicialTheme`: tema "neutro" para Welcome/Selector (antes de conocer el municipio). Usa dynamic color en Android 12+.
- `ServiciosPublicosTheme`: **un set de colores propio y fijo** (paleta morado/teal/verde estilo iOS) para el módulo de Servicios Públicos, con esquemas claro/oscuro independientes y extensiones semánticas (`statusSuccess`, `statusInfo`, `statusError`, `statusPending`). Este módulo NO usa el color del municipio.
- `darkTheme` se persiste en DataStore (`is_dark_theme`, `toggleTheme()`).

> **Flutter:** construir un `ThemeData` base y derivar `colorScheme.copyWith(primary: …, secondary: …)` desde los hex del backend. El escudo se carga con `cached_network_image` desde `idShield.url`. Mantener el tema separado de Servicios Públicos como un `Theme(...)` local del subárbol de ese módulo.

---

## 5. Catálogo de módulos / pantallas

Ruta de paquetes: `ui/screen/<feature>/`. Cada feature: `*Screen` (Compose) + `*ViewModel`.

### 5.1 Onboarding / sesión
- **SplashScreen** (`ui/screen/splash`) — Activity de launcher (tema `SplashTheme`).
- **WelcomeScreen** + `WelcomeViewModel` + `AdvertisementSection` — carrusel de anuncios (imágenes de Remote Config `welcome_carousel_images`, con `clickUrl`).
- **LoginOptionsScreen** + `LoginOptionsViewModel` — opciones: login email, registro, Google, invitado. (Lógica Google en §backend 5.2).
- **AuthScreen** + `AuthViewModel` — login email/contraseña.
- **SignUp** 3 pasos (`SignUpStep1/2/3Screen` + `SignUpViewModel`) — registro; componentes: `DatePickerField`, `DocumentTypeDropdown`, `MunicipalitySearchField`, `RegisterTextField`, `RegisterPasswordField`, `RegistrationSuccessOverlay`, `StepIndicator`. Soporta **draft** (borrador en DataStore) y prellenado desde Google.
- **RecoveryPasswordScreen** + `RecoveryPasswordViewModel` — recuperación.

### 5.2 Selección de municipio (solo modelo multi)
- **SelectMunScreen** + `SelectMunViewModel` — selector con `CheckboxSaveSelection` (guarda ubicación). `SelectMunicipality` componente. → **Se omite en apps individuales.**

### 5.3 Home del municipio
- **MainScreen** + `MainViewModel` — home. Componentes: `MainBottomNavBar`, `MainHeader` (muestra escudo + nombre alcaldía), `MainTopbar`, `MainSideMenuOptions`, `TramiteCard`, `TramitesSection`, `ModalForm` + `ModalFormViewModel` (formulario modal post-login, persistido con `modal_form_completed`).

### 5.4 Trámites (motor de decisión, ver §6)
Los trámites se renderizan como `TramiteCard` según `municipalityProcedures` del DTO.

### 5.5 PQRD
- **PqrdsChoiceScreen** (anónima vs identificada) + `PqrdsViewModel` + `PqrdState`.
- **PqrdAnonimaScreen**.
- **PqrdsIdentificationStep1/2/3Screen** (3 pasos).
- Componentes: `CustomDropdownPqrds`, `ErrorPqrdDialog`, `SuccessPqrdDialog`. Todos los catálogos (género, etnia, discapacidad, etc.) se piden por `CodigoEntidad` (§backend 3.16).

### 5.6 Impuestos
- **ConsultaImpuestoScreen** + `ConsultaImpuestoViewModel` — formulario dinámico según `queryFields` del DTO.
- **RespuestaConsultaScreen** + `RespuestaConsultaViewModel` — resultado + descarga de PDF.
- Componentes: `CardImpuesto`, `CustomAnimatedDropdownMenu`, `bottonSheet`, `DownloadCompletedReceiver` (BroadcastReceiver de descarga — en iOS no existe, reimplementar).

### 5.7 Certificados
- **CertificateStep1/2/3Screen** + `CertificatesViewModel` + `CertificatesNavScreen` — flujo 3 pasos parametrizado por `entityCode`/`procedureId`/`integrationType`.

### 5.8 Servicios Públicos (tema propio)
- **PublicServicesMenuScreen** + `PublicServicesMenuViewModel`.
- **PublicServicesScreen** + `PublicServicesForm`.
- **BillDetailsScreen** + `BillDetailsViewModel`.
- **BarcodeInstructionsScreen** + `CameraPreview` — **escaneo de código de barras/QR** (ML Kit + CameraX → `mobile_scanner` en Flutter). ⚠️ Probar pronto en iOS.
- ViewModels: `PSFPaymentViewModel`, `PSSValidationViewModel`. Componentes: `PublicServiceBottomBar`, `PublicServiceTopBar`, `UploadPdfButton`, `NavigationEvent`.

### 5.9 Pagos
- **PsvScreen** (Pago Sin Validación) + `PsvViewModel` + `Step1Form`/`Step2Form`/`Step3Summary`.
- **PaymentProcessingScreen** + `PaymentProcessingViewModel` + `ProcessingIndicator` — abre la URL de pasarela (Bancolombia) y monitorea estado.
- **HistoryPayScreen** + `HistoryPayViewModel` — historial de pagos.

### 5.10 Cursos ⭐ (requerido por Manizales)
- **CoursesScreen** + `CoursesViewModel`.
- **CourseDetailsScreen**, `CourseItem`, `RegistrationForm`, `RegisterOtlinedTextField`.
- Datos vía `CourseRepository`/`CourseService` (base URL propia vía `ApiFactory`). Se muestra si `MunicipalityDTO.courses` no está vacío.

### 5.11 Escenarios deportivos ⭐ (requerido por Manizales)
- **VenuesScreen** + `VenuesViewModel`.
- `VenueItem`, `ReservationForm` (envía email de reserva vía `SendEmail/Reservations`).
- Datos vía `VenueRepository`/`VenueService`. Se muestra si `MunicipalityDTO.sportsFacilities` no está vacío.

### 5.12 Recordatorios
- **RemindersScreen** + `RemindersViewModel` + `CalendarCustomReminder` — recordatorios locales (canal `reminders_channel`) + sincronización con API. `NotificationReceiver` (alarmas).

### 5.13 Soporte / Ayuda
- **HelpScreen** + `HelpViewModel` + `SupportFormWizard` + `SupportFormState` + `SupportFormInputs` — formulario de soporte que arma un email (`SupportEmailFormatter`/`SupportEmailProvider`) y lo envía vía `SendEmail`.

### 5.14 Perfil / Configuración
- **EditProfileScreen** + `EditProfileViewModel`.
- **UserSettingsScreen** + `UserSettingsViewModel` — incluye toggle de tema, cambio de municipio, eliminar cuenta.
- **ChangeOnlyPasswordScreen** + `ChangeOnlyPasswordViewModel` + `ReusableModal`, `ShowModalVerificationCode`, `VerificationCodeInput`.

### 5.15 Componentes compartidos (`ui/components/`)
`ConfirmationDialog`, `ConfirmationPoliciesDialog`, `ImportantAlertDialog`, `ValidationErrorDialog`, `NoConnectionDialog`, `PanicCountdownDialog`, `PolicyCheckboxes`, `RequestNotificationPermission`, `ShimmerLoadingAnimation`, `StepIndicator`, `SwipeUpDismissBox`, `TopbarNavigation`, `FooterSponsors`, `NotificationHelper`, `AlcaldiasStateWrapper`, `ErrorMunicipalityScreen`.
Utils (`utils/`): `BarcodeAnalyzer`, `CardStatusInfo`, `ChromeTabs` (`abrirURL`), `Formatters`, `InAppReviewManager`, `MyFirebaseMessagingService`, `NotificationReceiver`, `WebViewScreen`, `AppErrorStatusScreen`.

---

## 6. Motor de trámites (lógica de presentación crítica)

En `DataMappers.kt` (`MunicipalityDTO.toDomainModel()`), cada trámite del backend se convierte en un `InfoTramite` con ícono, color y **acción** (`TramiteAccion`). Esta lógica define toda la navegación del home y **debe portarse con cuidado**.

### 6.1 Mapa de íconos por ID de procedimiento (`tramiteConfigMap`)
| ID | Trámite | Categoría |
|---|---|---|
| 1 | Predial | MAIN |
| 2 | ICA | MAIN |
| 3 | Declaración | MAIN |
| 5 | Servicios (públicos) | MAIN |
| 6 | Vehículos | MAIN |
| 7 | Retención ICA | MAIN |
| 4 | PQRSDF | OTHER |
| 10 | Botón de Pánico | OTHER (color `PanicButton`) |
| 11 | Certificado Residencia | OTHER |
| 12 | Certificado Paz y Salvo | OTHER |
| 13 | Aporte a Turismo | OTHER |
| 14 | Concepto de Uso del Suelo | OTHER |
| 8 | Cursos | OTHER (módulo especial) |
| 9 | Reserva de espacios (Escenarios) | OTHER (módulo especial) |

Si un `procedureId` no está en el mapa → el trámite **no se muestra**.

### 6.2 Tipo de integración (`IntegrationTypeModel`)
- Si `entityCode` no está vacío → `TramitesporAPP(codigoEntidad, campoConsulta=queryFields)`.
- Si está vacío → `TramitesporURL(urlPredial, urlIca, urlPqrds, urlDeclaracion, urlReteIca)` extraídas de los `integrationType` de cada procedimiento.

### 6.3 Resolución de acción por trámite (`toInfoTramite`)
Orden de reglas (simplificado):
1. ID 10 o nombre contiene "Pánico" → `AbrirBotonPanico(integrationType, emailPanic)`.
2. `integrationType` vacío y ID 4 → `ShowPqrds` (navega a PQRD nativo).
3. ID 11/12/13/14 con `integrationType` no vacío → `NavegarANativo(CERTIFICATES_STEP1/{entityCode}/{id}/{integrationType})`.
4. `integrationType` vacío y ID 5 → `NavegarANativo(PUBLIC_SERVICE_SCREEN)`.
5. `integrationType` empieza por "http" → `AbrirUrl(integrationType)` (portal tributario externo, Chrome Tabs).
6. `integrationType == "psv"` → `NavegarAPagoSinValidacion(taxId, taxName, entityCode, políticas)`.
7. Else, si integración es `TramitesporAPP` → `NavegarAConsultaImpuesto(entityCode, queryFields, taxId, políticas)`.
8. Else → no hay acción → no se muestra.

### 6.4 Asignación de color dinámico
- MAIN y OTHER reciben color rotando paletas (`MainProcedureColors`, `OtherProcedureColors`) por bloques de 3 (`(index/3) % size`).
- Pánico (ID 10) conserva su color fijo `PanicButton`.
- SOCIAL (redes) usa `SocialMediaColor` + íconos por nombre (Facebook/Instagram/X/Youtube/Blogger/TikTok).

### 6.5 Módulos especiales como trámites
- Cursos (ID 8): si `courses.firstOrNull()` existe → `TramiteAccion.NavegarACursos(municipalityId, courseId, políticas, email)`.
- Escenarios (ID 9): si `sportsFacilities.firstOrNull()` existe → `TramiteAccion.NavegarAvenues(...)`.

> **Flutter:** portar `toInfoTramite`/`toDomainModel` como funciones puras de mapeo (idealmente con tests unitarios, dado que es la lógica más enredada y propensa a regresiones). Los íconos (`R.drawable.icopredial`, etc.) → assets en Flutter. El nombre de alcaldía se compone como `"Alcaldía de ${name}"`.

---

## 7. White-label en el cliente (resumen frontend)

| Aspecto | Trami App Municipios (multi) | Trami App Individual (Manizales) |
|---|---|---|
| Pantalla inicial | Welcome + SelectMunScreen | Directo al home del municipio |
| `municipioId` | Elegido por el usuario, guardado en DataStore | **Fijo por flavor** (build-time) |
| Colores / escudo / módulos | Del backend según `id` elegido | Del backend según `id` fijo |
| Selector de municipio | Visible | Oculto |
| Cambio de municipio (Settings) | Permitido | Oculto/deshabilitado |
| Tópico FCM | Acumulativo (`theme_<municipio>`) | Solo su municipio |
| Proyecto Firebase | El compartido | Propio de Manizales |
| Nombre app / bundle id / ícono | Trami App Municipios | Trami App Manizales / bundle propio |

**Lo único que cambia entre apps es build-time (flavor) + qué proyecto Firebase usa.** Todo lo visual y de módulos sigue viniendo del backend por `id`. → Un cambio de código Flutter aplica a todas las apps al recompilar cada flavor; un cambio del backend aplica instantáneo sin recompilar.

---

## 8. Notificaciones (comportamiento)

- **Canales:** `firebase_notifications_channel` (default), `firebase_campaigns_channel` (campañas), `reminders_channel` (recordatorios locales).
- **FCM (`MyFirebaseMessagingService`):** lee `data["type"]` y `data["url"]`. Si `type == "campaign"` y hay `url` → notificación de campaña que, al tocarse, abre la URL en Chrome Custom Tabs (`handleCampaignIntent` en `MainActivity`, extra `campaign_url`). Si no → notificación default que abre `MainActivity`.
- **Suscripción por tópico de municipio** (§backend 7.5).
- **Permisos:** `POST_NOTIFICATIONS` (Android 13+) se pide en `onCreate`.

> **Flutter / iOS:** `firebase_messaging` + `flutter_local_notifications` para canales. En iOS configurar APNs key (.p8) en Firebase y permisos en `Info.plist`. El "abrir URL desde notificación de campaña" se reimplementa con manejo de `onMessageOpenedApp` + `url_launcher`.

---

## 9. Permisos declarados (AndroidManifest) y su traducción iOS

| Android | Uso | iOS (Info.plist) |
|---|---|---|
| `INTERNET`, `ACCESS_NETWORK_STATE` | Red | (implícito) |
| `CAMERA` | Escaneo barcode/QR | `NSCameraUsageDescription` |
| `ACCESS_COARSE/FINE_LOCATION` | Clima (deshabilitado) / ubicación | `NSLocationWhenInUseUsageDescription` |
| `POST_NOTIFICATIONS` | Push | permiso runtime de notificaciones |
| `READ/WRITE_EXTERNAL_STORAGE` (≤32) | Descarga PDF | manejo vía file provider / share sheet |
| `SCHEDULE_EXACT_ALARM` | Recordatorios | notificaciones locales programadas |
| `VIBRATE` | Notificaciones | — |

Otros del manifest: orientación **portrait** forzada en las activities; `usesCleartextTraffic=true` (no portar a iOS — usar HTTPS); intent `OPEN_CAMPAIGN`; receiver `DOWNLOAD_COMPLETE`.

---

## 10. Consideraciones específicas iOS (frontend)
1. **Safe Area / notch:** los layouts con bottom nav deben respetar el home indicator (`SafeArea`).
2. **Descarga de PDFs:** no hay `DownloadManager` ni `DownloadCompletedReceiver`; usar `dio` (stream a archivo temporal) + `open_filex`/share sheet.
3. **In-App Update IMMEDIATE:** no existe; confiar en App Store.
4. **In-App Review:** Apple limita el prompt (máx ~3/año por usuario); no forzar.
5. **Cámara (mobile_scanner):** probar en iPhone físico temprano (diferencias de rendimiento/permiso).
6. **Google Sign-In iOS:** requiere `REVERSED_CLIENT_ID` en `Info.plist` + `GoogleService-Info.plist` del proyecto Firebase del flavor.
7. **Status/navigation bar:** el manejo edge-to-edge de Compose se traduce a `SystemUiOverlayStyle` en Flutter.

---

## 11. Deuda técnica / oportunidades en la migración (frontend)
1. **`toInfoTramite` muy ramificado** → portar con tests; candidato a simplificar con un modelo de acciones más declarativo.
2. **Datos largos viajando por rutas** (URLs de políticas, JSON de queryFields en la ruta) → en Flutter pasar por `extra`/estado, no por path params.
3. **Analytics reimplementable** (indicado por el equipo) → rediseñar el tracking de eventos/clics por módulo en vez de copiar.
4. **Clima deshabilitado** (código comentado en `MunicipalityViewModel`) → decidir si se reactiva.
5. **Dos `Theme.kt`/`StepIndicator`** y temas múltiples → unificar sistema de theming en Flutter.
6. **Tópico FCM acumulativo** en app multi → en apps individuales suscribir solo al municipio propio.
7. **`signOut()` al arrancar** (limpia Google/Firebase) → revisar si el comportamiento es intencional al portar.

---

*Generado a partir del código de la rama `main` (Trami App Municipios, Android/Kotlin + Compose). Versión base: 1.4.4 (versionCode 46). Migración a Flutter desde cero, prioridad Trami App Manizales (iOS + Android).*
