# Roadmap de migración — checklist accionable

> Lista viva de tareas. **Marca cada casilla `[x]` al completarla.** El orden importa: las fases de abajo dependen del núcleo de arriba. Módulos tomados del catálogo de `MIGRACION_FLUTTER_FRONTEND.md §5`.

Leyenda: ⚙️ infraestructura · 🤖 automatizable con agente · 🍎 requiere atención iOS · 🟦 requerido por Manizales

---

## Estado a 2026-08-13 (auditoría contra el código)

Cifras medidas sobre el repo, no estimadas:

| Métrica | Valor |
|---|---|
| Líneas Dart (sin generados) | 31.031 en 316 archivos |
| Features migradas | 17 |
| Paquetes de pantallas Kotlin cubiertos | 21 / 21 |
| DTOs traducidos | 132 |
| Servicios Retrofit | 14 |
| Base URLs (todas HTTPS) | 6 / 6 |
| `flutter analyze` | 0 issues |
| Tests | 34 pasando, 6 archivos (7 nuevos de componentes compartidos, 2026-08-19) |

**Avance:** funcionalidad Android ~90 % · iOS ~10 % · proyecto global ~72 %.

La app es **funcionalmente completa en Android**: no quedan módulos por migrar. Lo pendiente es
cerrar iOS, consolidar componentes compartidos, pulir detalles visuales y publicar.

> ⚠️ **Aviso de dirección (2026-08-13).** Entra un **cambio de patrocinador**: mismo backend y misma
> base de código, pero nuevo producto con giro a lo ciudadano/cultural/educativo y funcionalidades
> nuevas. El alcance está mapeado en [`PRODUCTO_2_ALCANCE.md`](PRODUCTO_2_ALCANCE.md). Este roadmap
> sigue rigiendo el cierre de Centralización, que es la base sobre la que se construye el producto 2.

---

## Fase 0 — Setup del proyecto Flutter ⚙️

- [x] Crear proyecto Flutter (`tramiapp_flutter`) con soporte iOS + Android
- [x] `applicationId` = `com.tramites1cero1.centralizacion` (Android; `bundleId` iOS en Fase 5)
- [x] Estructura de carpetas según `CONVENCIONES.md` (`core/`, `features/`, `flavors/`)
- [x] `pubspec.yaml` con dependencias del stack (dio, retrofit, riverpod, go_router, json_serializable, firebase_*, mobile_scanner, cached_network_image, etc.) — `flutter_inappwebview` pospuesto (incompatible con AGP 9; se reañade cuando haya versión compatible o vía `url_launcher`)
- [x] Configurar `build_runner` + `json_serializable` (verificado con `shield_dto`)
- [x] Scaffold de flavors `municipios` y `manizales` (ver `FLAVORS.md`) — solo el `municipios` se desarrolla por ahora
- [x] FlutterFire: `firebase_options_municipios.dart` apuntando al proyecto Firebase actual (`betaappcentralizate`, Android; iOS pendiente)
- [x] Copiar `CLAUDE.md` y los `MIGRACION_FLUTTER_*.md` a la raíz del proyecto Flutter (ya viven en la raíz del repo y en `docs/`)
- [~] GitHub Actions: build APK + IPA por flavor (mac-runner) — APK `municipios` hecho (ver [`CI_CD.md`](CI_CD.md)); faltan `manizales` e IPA
- [ ] **Iniciar Apple Developer Account** (proceso externo, puede tardar hasta 2 semanas) 🍎

> ✅ **Fase 0 verificada**: `flutter analyze` limpio + `assembleMunicipiosDebug` genera `app-municipios-debug.apk`. Notas: AGP 9 requirió habilitar `coreLibraryDesugaring` (lo pide `flutter_local_notifications`) y se quitó `flutter_inappwebview`. Firma release lista vía `key.properties` (pendiente la contraseña del keystore).

## Fase 1 — Núcleo (core) ⚙️

- [x] Cliente Dio único + `BaseOptions` (timeouts 40s) — `core/api/dio_client.dart`
- [x] Interceptor global de errores (`GlobalErrorInterceptor`) → estado global de app — `core/api/global_error_interceptor.dart`
- [x] Factory de servicios por base URL (las 6 de `BACKEND.md §2`) — `core/api/network_provider.dart` + `dioProvider` (servicios Retrofit pendientes)
- [x] 🤖 Traducir DTOs Kotlin → Dart con el agente `migration-agent/` — `BACKEND.md §4` — **66 archivos `.dart` compilando** (`dart analyze lib/core/models` limpio). Cubre auth/sesión, grafo completo de `MunicipalityDTO`, pagos/tax/fintech, reminders, email, people, weather y PQRD 24/24. Los `.kt` con varias `data class` quedaron en un solo `.dart` (p. ej. `tax_dto.dart`=10 clases). Hecho en lotes con Haiku (catálogos) + Sonnet (complejos). Agente endurecido: reintentos 529, encoding UTF-8, verify tolerante a codegen, `lowerCamelCase + @JsonKey`, `leer_kotlin` tolerante a rutas.
- [x] Servicios Retrofit por microservicio (Auth, Municipality, Tax, PQRD, Generales, etc.)
- [x] Persistencia local (DataStore → shared_preferences): sesión, ubicación guardada, tema — `core/storage/user_preferences.dart`
- [x] Estado global de app (`AppStatusManager` → provider Riverpod): operational/maintenance/force_update/server_error — `core/api/app_status.dart`
- [x] FlutterFire: Crashlytics, Analytics, Remote Config, Messaging
- [x] Remote Config con las 4 keys: `welcome_carousel_images`, `app_status_config`, `send_to_welcome`, `tourism_tax_rates` — `BACKEND.md §6.1`
- [x] Theming dinámico desde backend (`Theme` hex → `ThemeData`) — `core/theme/` (`color_parser`, `design`, `app_theme`)
- [x] Navegación con go_router (equivalente a los grafos anidados) — `FRONTEND.md §2`
- [x] Lógica de arranque / `startDestination` (welcome vs municipio guardado) — `FRONTEND.md §1.1`

> ✅ **Fase 1 verificada**: Capa de red, servicios Retrofit, persistencia local, theming dinámico, integración con Firebase (Crashlytics, Analytics, Remote Config, Messaging) y navegación con go_router completamente implementadas.

## Fase 2 — Onboarding, sesión y home

- [x] Splash + Welcome + carrusel de anuncios
- [x] Login nativo (correo/clave) contra la API — `BACKEND.md §5.1`
- [x] Login con Google (Firebase Auth + google_sign_in) — `BACKEND.md §5.2` 🍎
- [x] Registro en 3 pasos (con borrador/draft y prellenado desde Google)
- [x] Recuperación de contraseña
- [x] Selector de municipio (solo flavor `municipios`)
- [x] MainScreen: bottom nav + header (escudo + nombre) + side menu
- [x] Notificaciones push (FCM) + notificaciones locales + canales 🍎
- [x] Módulo Noticias

> ✅ **Fase 2 verificada**: Pantallas de onboarding, selector de municipios, login nativo y con Google, registro wizard en 3 pasos, recuperación de contraseña, pantalla principal (Home), módulo de noticias e integración de notificaciones push y locales completamente implementados.
>
> 🎨 **Pulido de UI de la Home (2026-08-19)** — cotejado contra `MainScreen.kt` y sus componentes:
> - **Adorno `circles` que faltaba por completo.** El original dibuja `R.drawable.circles` en la
>   esquina superior derecha de Home, Historial, Cursos y Escenarios; no había asset ni widget en
>   Flutter. Portado a `assets/images/circles.svg` + `core/widgets/circles_decoration.dart` con los
>   dos presets del original (Home: 110 dp sin rotar, blanco al 20 %; el resto: 120 dp rotado 90°,
>   `primary` al 70 %).
> - **Bottom nav con íconos genéricos de Material** (`Icons.home/newspaper/language/history`) en vez
>   de los de la marca. Ahora usa `icohome`/`iconoticias`/`icoportal`/`icohistorial`, que ya estaban
>   en `assets/images/` sin consumir.
> - **Diálogo de salida suelto.** Era un `AlertDialog` crudo; ahora usa el `ConfirmationDialog`
>   compartido (mismo caso que el "Próximamente disponible" del PR #20). Además **el botón "Sí, salir"
>   no cerraba la app**: `onConfirmExit` del original hace `FinishApp` cuando hay municipio guardado y
>   solo va a Welcome cuando no lo hay; el Flutter iba a Welcome en ambas ramas. Corregido con
>   `SystemNavigator.pop()`.
> - **Teclado que no se cerraba al tocar fuera** (el `clickable { focusManager.clearFocus() }` que
>   envuelve el contenido en `MainScreenContent`). Añadido en Home y en Certificados.
> - **Espaciados**: 10 dp entre secciones y sin padding inferior extra (`spacedBy(10.dp)` +
>   `contentPadding` del `LazyColumn` original, que usaba 16) y 5 dp entre tarjetas de trámite
>   (`Arrangement.spacedBy(5.dp)`, que no se había portado).
>
> 🐛 **Bug de logout cerrado (PR #20, 2026-08-19)**: tras cerrar sesión, el side menu seguía mostrando
> el saludo y "Cerrar sesión" del usuario anterior. Causa: `MainUiState.copyWith(currentUser: next)`
> usaba `currentUser ?? this.currentUser` — con `next == null` (logout), `??` descarta el `null` y
> conserva el valor viejo, así que el campo nunca podía volver a quedar en `null`. El Kotlin original
> no tiene este problema porque `data class.copy()` sí acepta `null` explícito. Arreglado con un flag
> `clearCurrentUser` (mismo patrón que ya usan `clearModalMode`/`clearPendingUrl`/`clearUrlToOpen`).
>
> 🐛 **Recuperación de contraseña incompleta (2026-08-19)**: `RecoveryPasswordScreen` enviaba el
> código de verificación por correo (`sendEmailValidationCode`) pero nunca migró el paso siguiente —
> no existía ningún lugar donde introducirlo, ni la pantalla final para fijar la nueva contraseña.
> Faltaban los equivalentes de `ShowModalVerificationCode.kt`/`VerificationCodeInput.kt` (hoja modal
> de 6 dígitos) y `ChangeOnlyPasswordScreen.kt`. Se portó el flujo completo y fiel: `RecoveryPasswordNotifier`
> (envío + validación local del código contra el `extraData` que devuelve el backend — no hay endpoint
> de verificación en servidor, ver `BACKEND.md §3.12`, bloqueo de 5 min tras 3 intentos), la hoja
> `VerificationCodeSheet`/`VerificationCodeInput`, y `ChangePasswordResetScreen`/`ChangePasswordResetNotifier`
> (`PUT api/User/updatePasswordByForget/{userId}`). Rutas nuevas en `app_routes.dart`/`app_router.dart`.
>
> _Nota de fidelidad de puerto:_ Kotlin resetea a `MAIN_NAV_GRAPH` (`popUpTo(0)`) al terminar; en
> go_router (rutas empujadas con `push`, no un grafo separado) el equivalente correcto es deshacer la
> pila de rutas del flujo (`while (context.canPop()) context.pop()`), lo que devuelve a la pantalla de
> origen con la sesión ya activa — incluido en la implementación.

## Fase 3 — Módulos core

- [x] Trámites + motor de decisión `toInfoTramite`/`toDomainModel` (portar con tests) — `FRONTEND.md §6`
- [x] PQRD (anónima + identificada, 3 pasos; catálogos por `CodigoEntidad`)
- [x] Impuestos (consulta dinámica por `queryFields` + respuesta + descarga PDF) 🍎
  - [x] Repaso de fidelidad 2026-07: UI portada de `TaxQueryScreen.kt`/`RespuestaConsultaScreen.kt`, validaciones en notifier, botón "Pagar por PSE" (Custom Tabs/Safari VC vía `abrirUrl`), descarga + compartir factura PDF (`share_plus`), registro en historial y pantalla "Procesando tu pago" con countdown
- [x] Certificados (3 pasos)
  - 🎨 **Fidelidad 2026-08-19**: la pantalla usaba un `AppBar` plano en vez de la cabecera
    `TopbarNavigation` del original (insignia con el ícono del certificado + "Pide, paga y recibe tu
    certificado."), y un indicador de pasos numerado propio en vez del compartido. De paso,
    `_getIconPath` devolvía rutas `.png` inexistentes (los assets son `.svg`); el campo nunca se
    pintaba, así que el error estaba latente hasta que la cabecera empezó a consumirlo.
- [x] Servicios Públicos + escáner QR/barcode (`mobile_scanner`) 🍎
- [x] Pagos: PSV + PaymentProcessing (pasarela) + estado de transacción
- [x] Historial de pagos
  - 🎨 **Fidelidad 2026-08-19**: portada la cabecera `TopbarNavigation` con el ícono
    `ico_calendar_history` (vector drawable convertido a SVG), el marco redondeado del original
    (borde `primary` al 20 % con radio 25 sobre superficie con radio 20) y el adorno `circles`.
    Antes era un `AppBar` plano titulado "Historial de Pagos".

> ✅ **Fase 3 verificada**: Módulos core (Trámites con mappers y tests unitarios, PQRD, Impuestos con consulta y descarga de PDF, Certificados en 3 pasos, Servicios Públicos con escaneo de código de barras, Pagos PSV y pasarela, e Historial de pagos) completamente implementados en el código Dart.
>
> 🔧 **Repaso motor de trámites 2026-07-07 (acciones de botón)**: verificado que `toInfoTramite`/`toDomainModel` mapean las 8 reglas de `FRONTEND.md §6.3` (Pánico, PQRD nativo, Certificados, Servicios Públicos, **PT/portal tributario** `AbrirUrl`, PSV, Consulta de impuesto, Cursos/Escenarios). **Corregido el despacho del PT**: `AbrirUrl`/`AbrirUrlDirecto` ahora abren con el navegador in-app (`abrirUrl()` → Chrome Custom Tabs / Safari VC) tintado con el color del municipio, igual que `abrirURL(context, url, colorPrimario)` del original; antes usaban `launchUrl(externalApplication)`. Mismo cambio en las 3 URLs del Home (términos, noticias, portal `domain`).
>
> 🎨 **Fidelidad UI PSV 2026-07-17**: reescrito `psv_wizard.dart` para replicar fielmente `PsvScreen.kt` + `Step1/2/3` + `FormButtons`: cabecera `primary` con badge circular e ícono del impuesto ("Pago Seguros en Línea" + nombre), hoja redondeada, `StepIndicator` con checks, y los campos/títulos correctos por paso — Paso 1 "Datos del ciudadano o contribuyente" (tipo doc del backend + primer/segundo nombre y apellido), Paso 2 "Datos de pago" (tipo impuesto readonly, correo, teléfono, factura, valor con `$`/separadores + políticas), Paso 3 "Resumen de pago" (tarjeta gris + tarjeta roja "Importante"). Ahora consume el `ValidationErrorDialog` centralizado. **Transacción**: `onPay` registra el historial (`createHistoryPay` → `POST api/PaymentHistory`) y crea la transacción (`createTransaction`), igual que `onPayClicked` del `PsvPaymentViewModel`.
>
> 🐛 **Trámites inactivos navegaban igual (PR #20, 2026-08-19)**: un trámite con `isActive = false`
> (p. ej. Cursos/Reserva de espacios en Amalfi) mostraba el diálogo "Próximamente disponible" **y**
> abría la pantalla igual. Causa: `MainScreen.onTramiteClick` llamaba a
> `notifier.onTramiteClicked(t)` (que sí corta en seco si `!isActive`) pero luego invocaba
> `_handleNavigation(t)` sin condición, solo filtrando por tipo de `accion`. En el Kotlin original la
> navegación es 100 % dirigida por evento desde el ViewModel y nunca se dispara para un trámite
> inactivo. Se agregó el check de `isActive` que faltaba en las dos secciones (Trámites / Otros
> trámites). De paso, el diálogo "Próximamente disponible" usaba un `AlertDialog` suelto en vez del
> `ConfirmationDialog` centralizado (por eso el padding/ícono se veían distintos al resto de diálogos
> de la app) — ya consume el componente compartido.

## Componentes compartidos (`core/widgets`) — `FRONTEND.md §5.15`

- [x] Centralizados en `core/widgets/` (antes dispersos en features): `ConfirmationDialog`, `ImportantAlertDialog`, `FooterSponsors`, `PolicyCheckboxes` (+`PolicyCheckboxRow`), `PanicCountdownDialog`, `SwipeUpDismissBox`.
- [x] Portados fielmente del codebase: `ErrorMunicipalityScreen` (cableado en `AlcaldiasScope`, reemplaza el stub), `ValidationErrorDialog`, `ConfirmationPoliciesDialog`.
- [x] `AlcaldiasStateWrapper` → implementado como `AlcaldiasScope` (theming dinámico) en `core/router/placeholders.dart`.
- [x] `RequestNotificationPermission`: cubierto por `core/notifications` (FCM `requestPermission` + locales `requestNotificationsPermission`) — no requiere widget.
- [x] **Consumir los dialogs centralizados** — `ValidationErrorDialog` cableado en PSV y `ConfirmationPoliciesDialog` en PQRD paso 3. *(Certificados queda con SnackBars a propósito: el `ValidationErrorDialog` también está comentado en el `CertificatesNavScreen.kt` original, así que el port es fiel — no es una desviación.)* El diálogo "Próximamente disponible" de `MainScreen` (trámites inactivos) también consume `ConfirmationDialog` desde el 2026-08-19 (PR #20) — antes era un `AlertDialog` suelto, sin el padding/header/ícono del componente compartido.
- [x] `NoConnectionDialog`: observador de conectividad (`core/connectivity`, sobre `connectivity_plus`), notifier con debounce de 3 s, diálogo compartido superpuesto en `GlobalStatusOverlay` y chequeo de red en el Splash (`FRONTEND.md §3`).
- [x] `TopbarNavigation` compartido → `core/widgets/top_bar_navigation.dart` (`TopBarNavigationScaffold`, antes `PqrdScaffold`, que ya era el port fiel pero estaba encerrado en PQRD). Lo consumen las pantallas cuyo original llama a `TopbarNavigation`: PQRD anónima, PQRD con identificación, **Certificados** e **Historial de pagos** (estas dos tenían un `AppBar` plano). PSV conserva su `SliverAppBar` propio por el badge del impuesto, pero ya usa el botón de retroceso compartido. Se le añadieron `bottomBar` (barra fija fuera del scroll) y `onRefresh` (equivalente al `PullToRefreshBox` del Historial).
- [x] `AppBackButton` (`core/widgets/app_back_button.dart`): el botón circular de "atrás" estaba **duplicado en 7 pantallas** (`_CircleBackButton`/`_CircularBackButton` + dos copias inline) y con tamaños de ícono distintos (18 vs 20 px). Un solo componente con los dos estilos del original: `filled` (círculo `primary` + flecha `onPrimary`, para barras sobre fondo claro — Editar perfil, Configuración, Consulta/Respuesta de impuesto, Cursos, Escenarios) y `light` (círculo blanco + flecha `primary`, para barras sobre el color del municipio — `MainTopBar`, `TopbarNavigation`, PSV).
- [x] `StepIndicator`: unificado en el canónico. Se borró la copia `_StepIndicator` de `psv_wizard.dart` y el indicador numerado inline de `certificates_wizard.dart` (que ni siquiera era el diseño del original: usaba `CircleAvatar` con números en vez de círculos con check). De paso el canónico se ajustó al `StepIndicator.kt` real: divisor de 1 dp con `surfaceVariant` y fila centrada verticalmente. *(Corrección al inventario anterior: `features/auth/.../signup_step_row.dart` **no** es una copia — `signup/components/StepIndicator.kt` es otro componente del original, con círculos numerados y sin check.)*
- [x] `NotificationHelper`: notificaciones locales de confirmación de Cursos/Escenarios (`core/notifications/registration_notifications.dart`, sobre `LocalReminderScheduler.showNow` con `bigText`). Ids `2000001`/`2000002` (el Kotlin usaba `1`/`2`; aquí podían pisar recordatorios del servidor). **Pendiente:** QA manual en dispositivo (permiso denegado, texto expandible).

## Fase 4 — Módulos + perfil

- [x] 🟦 Cursos (`CourseRepository` → Flutter)
- [x] 🟦 Escenarios deportivos (`VenueRepository` → Flutter, reserva + email)
- [x] Recordatorios + calendario
- [x] Soporte / Ayuda (formulario → email)
- [x] Editar perfil + configuración de usuario + cambio de contraseña

> ✅ **Fase 4 verificada en dispositivo (PR #17, 2026-08-13)** — Redmi Note 10 5G, Android 13, MIUI 14.
>
> **Recordatorios — bug de alarmas cerrado.** El síntoma era que la notificación inmediata sí llegaba
> y la programada no, o llegaba tarde. Causa: en Android 12+ `exactAllowWhileIdle` exige
> `SCHEDULE_EXACT_ALARM` y **nunca se pedía en runtime**; `zonedSchedule` lanzaba
> `exact_alarms_not_permitted`, el `catch` caía en silencio a `inexactAllowWhileIdle` y el sistema
> agrupaba la alarma. Ahora se verifica con `canScheduleExactNotifications()` y se pide antes de
> agendar; `schedule()` devuelve `ScheduleOutcome` (`exact`/`inexact`/`failed`) para que la UI no
> prometa una hora que no va a cumplir.
>
> **Riesgo de publicación corregido:** se quitó `USE_EXACT_ALARM` del manifest. Se autoconcede, pero
> la política de Google Play lo restringe a apps de alarma o calendario; declararlo arriesgaba el
> rechazo del envío.
>
> **Verificado bajo Doze profundo** (`deviceidle force-idle`, pantalla apagada): la alarma mantuvo
> `window=0` y `whenElapsed == maxWhenElapsed` con `device_idle` sin aplazarla, y la notificación se
> publicó puntual (`NotificationRecord`, `channel=reminders_channel`). La app **no** está en la
> whitelist de batería, así que no se debe a ninguna exención. De paso quedó validada la zona horaria
> fija `America/Bogota` contra el reloj real del dispositivo.
>
> ⚠️ **Sin cubrir:** el flujo de *solicitud* del permiso cuando no está concedido. En Android 13
> `SCHEDULE_EXACT_ALARM` viene pre-concedido, así que ese camino solo se ejerce en **Android 14+** o
> revocándolo a mano. Pendiente de probar en un dispositivo con Android 14/15.

## Deuda técnica e infraestructura (auditoría 2026-08-13)

Nada de esto bloquea la app hoy, pero encarece cada cambio y hay que cerrarlo antes de escalar a
varios productos.

- [x] **Excluir `codebase/**` y `build/**` del analizador** — `flutter analyze` recorría los 23.596
      archivos del espejo Android en cada corrida: **806 s → ~13 s**. (PR #17)
- [x] **`force_update` estaba desactivado de facto** — `kAppBuildNumber` era la constante `999999`,
      así que `build < minVersionCode` no se cumplía nunca. Ahora sale del bundle nativo vía
      `package_info_plus` (`core/utils/app_info.dart`), con `999999` solo como fallback seguro. (PR #17)
- [x] **Test de arranque que no probaba nada** — afirmaba "aterriza en Welcome" pero solo avanzaba
      600 ms y el splash espera 3600 ms, así que validaba el splash. (PR #17)
- [ ] **Cobertura de tests**: 5 archivos para 31 k líneas, y solo `tramite_mappers_test.dart` cubre
      lógica de negocio real. Prioridad: mappers de trámites, validaciones de formularios, `AppStatus`.
- [~] **GitHub Actions**: `ci.yml` (analyze + test en PRs a `develop`/`main`) y `release-apk.yml` (APK
      firmado solo al fusionar `develop` → `main`) añadidos; ver [`CI_CD.md`](CI_CD.md). **Pendiente:** cargar
      los secretos del repo (keystore y `google-services.json`), flavor `manizales` e iOS (IPA).
- [ ] **Un test golpea la API real** (`GET /api/Department` devuelve 400 en la suite). Debe usar mock.

## Fase 5 — Ajuste iOS 🍎

> ⚠️ **iOS está como lo dejó `flutter create`.** `ios/Runner/Info.plist` conserva la fecha de creación
> del proyecto y solo las claves de plantilla; solo existe `Runner.xcscheme`. El código Dart sí es
> multiplataforma y las 6 base URLs son HTTPS (sin bloqueo de ATS), así que el trabajo es de
> configuración nativa, no de migración. **Requiere un Mac y la cuenta de Apple Developer.**

- [ ] **`NSCameraUsageDescription` en `Info.plist`** — sin esto `mobile_scanner` **crashea al abrir**
      el escáner de servicios públicos. Es el fallo más inmediato al arrancar en iOS.
- [ ] Resto de permisos en `Info.plist` (ubicación, notificaciones)
- [ ] Schemes/configs por flavor en Xcode
- [ ] `GoogleService-Info.plist` por flavor (no existe ninguno)
- [ ] APNs Auth Key (.p8) en Firebase para FCM
- [ ] `REVERSED_CLIENT_ID` para Google Sign-In
- [x] Descarga de PDFs sin DownloadManager (`dio` + `open_filex`)
- [ ] Safe Area / home indicator en layouts con bottom nav
- [ ] Pruebas en iPhone físico → TestFlight

> 🍎 **Iniciar ya la cuenta de Apple Developer**: es el único punto con espera externa (hasta dos
> semanas) y no es trabajo, es una fila. Debe arrancar en paralelo con todo lo demás.

## Fase 6 — QA y publicación de Centralización

- [ ] QA funcional completo iOS + Android
- [ ] Rendimiento (Firebase Performance + Crashlytics)
- [ ] Revisión App Store Guidelines
- [ ] Publicar en Play Store y App Store

## Fase 7 — Trami App Manizales (flavor) 🟦

> Solo después de terminar Centralización. Seguir el playbook de `FLAVORS.md §11`.

> ⚠️ **Esta fase estaba marcada en cero pero va por la mitad.** El trabajo vive en la rama
> `claude/manizales-shield-flavor-apk-41c6c7` (commit `91df762`), que **sigue sin PR y sin mezclar en
> `develop`**. Además del flavor, aporta la regla proguard `-dontwarn androidx.window.**` que arregla
> R8 en release **para ambos flavors** — conviene no dejarla colgando.

- [x] Confirmar `id` y `entityCode` de Manizales en el backend — `id = 213`
- [~] Proyecto Firebase de Manizales — **temporal**: reusa `betaappcentralizate` con `appId` propio de Android. Falta proyecto propio, iOS, APNs y las 4 keys de Remote Config.
- [x] `flavors.dart` + `main_manizales.dart`
- [~] productFlavor Android hecho (`com.tramitesapp.manizales`); **scheme iOS pendiente**
- [~] `google-services.json` puesto; **`GoogleService-Info.plist` pendiente**
- [x] Ícono, nombre y colores de la Alcaldía de Manizales (escudo como ícono de launcher)
- [ ] Bundle id + Provisioning Profile en Apple Developer
- [~] APK release generado y verificado; **publicación pendiente**
- [ ] Documentar el playbook validado para los siguientes municipios

Leyenda: `[~]` = parcial.
