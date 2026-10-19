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
- [x] **Iniciar Apple Developer Account** (proceso externo, puede tardar hasta 2 semanas) 🍎 — cuenta creada (2026-10-19)

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
- [x] Eventos de Analytics y tópico FCM por municipio (2026-10-19) — la migración había dejado `AnalyticsService` sin llamadas y sin `subscribeToTopic`. Paridad con Kotlin + propiedad de usuario `municipio`, parámetros sin URLs/PII y `login`/`sign_up` en el momento correcto. Catálogo en [`ANALITICA_EVENTOS.md`](ANALITICA_EVENTOS.md)
- [x] Analítica Fase 1: embudo del pago por pasarela integrada (2026-10-19) — `consulta_impuesto_enviada/_resultado`, `pasarela_abierta`, `pago_verificado`, `purchase` (COP, solo con aprobado confirmado por el backend, `transaction_id` = id del historial) y `pago_error`. Impuestos, PSV y certificados. Ver [`ANALITICA_EVENTOS.md`](ANALITICA_EVENTOS.md)
- [x] Analítica Fase 2: portales externos (2026-10-19) — `portal_externo_abierto/_regreso` (tiempo fuera, sobrevive a que Android cierre la app) y microencuesta "¿Pudiste hacer tu pago?" para impuestos (≥ 20 s fuera, una vez cada 15 días por trámite). En iOS solo la apertura. Ver [`ANALITICA_EVENTOS.md`](ANALITICA_EVENTOS.md)
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
- [x] `AppTopBar` (`core/widgets/app_top_bar.dart`) + posición única del botón de atrás (2026-10-07): el botón medía 35 px en unas pantallas y ~46 px en otras (el `leading` del `AppBar` lo estiraba) y estaba a 8/10/15/16 px del borde y a alturas distintas. Ahora `AppBackButton` no se deforma y define `edgeInset` (14 px) y `barHeight` (64 px, `TopAppBar` M3); `AppTopBar` (botón + título) reemplaza los `AppBar` armados a mano en PQRSDF (elección), Configuración, Editar perfil, Consulta/Respuesta de impuesto, Cursos, Detalle de curso, Espacios deportivos, Noticias, Ayuda, Cambiar contraseña y las 7 de Servicios Públicos. `MainTopBar`, `TopBarNavigationScaffold`, PSV y Registro usan las mismas medidas.
- [x] `StepIndicator`: unificado en el canónico. Se borró la copia `_StepIndicator` de `psv_wizard.dart` y el indicador numerado inline de `certificates_wizard.dart` (que ni siquiera era el diseño del original: usaba `CircleAvatar` con números en vez de círculos con check). De paso el canónico se ajustó al `StepIndicator.kt` real: divisor de 1 dp con `surfaceVariant` y fila centrada verticalmente. *(Corrección al inventario anterior: `features/auth/.../signup_step_row.dart` **no** es una copia — `signup/components/StepIndicator.kt` es otro componente del original, con círculos numerados y sin check.)*
- [x] `NotificationHelper`: notificaciones locales de confirmación de Cursos/Escenarios (`core/notifications/registration_notifications.dart`, sobre `LocalReminderScheduler.showNow` con `bigText`). Ids `-1`/`-2` (el Kotlin usaba `1`/`2`; aquí podían pisar recordatorios del servidor, que usan `id` e `id + 1000000` positivos). **Pendiente:** QA manual en dispositivo (permiso denegado, texto expandible).
- [x] In-App Review (`core/review/review_prompt_service.dart`, sobre `in_app_review`): regla del Kotlin (2.º login nativo; Google no cuenta) **más** momentos de éxito añadidos al migrar (FSM-59): PQRD radicada, volver de resultados de consulta de impuesto, cerrar la confirmación de inscripción a curso o reserva de escenario, y pago aprobado. Como mucho un flujo completado por sesión de la app (el Kotlin: una sola vez para siempre). **Pendiente:** verificación real con una build instalada desde la pista interna de Play.
- [x] In-App Update (Play Core) (`core/update/`, sobre `in_app_update`): actualización **inmediata** al arrancar (también reanuda una descarga a medias tras un arranque en frío), como `checkForAppUpdate()` de `MainActivity.kt`. El `onResume()` del Kotlin no se porta en Dart: el plugin ya reanuda en nativo (`onActivityResumed`) y repetirlo abría un segundo flujo. Solo Android; convive con el `force_update` de Remote Config. **Pendiente:** verificación en Play (requiere dos versiones subidas a la pista interna, N y N+1).
- [x] Animaciones (PR #18): transiciones de ruta de `NavigationAnimations.kt` / `AppNavGraph.kt` en `core/router/app_transitions.dart` (`appPage()`: `standard` 300 ms sin fade y `parallax` 500 ms + fade, asignadas por ruta según el `composable` Kotlin; iOS conserva `CupertinoPage` para el gesto de volver). Widgets compartidos `EnterTransition` (≈ `AnimatedVisibility` fade + slide) y `SlideSwitcher` (≈ `AnimatedContent` direccional) en `core/widgets/`. Portado en Selección de municipio, Recordatorios (flechas, rotación Y, dropdown, calendario), pasos de Certificados / PQRD identificada / Soporte / Signup, dropdowns de Welcome y Signup, `FooterSponsors`, `AnimatedSection` del home (500 ms, 10 dp) y alertas menores. **Pendiente:** QA visual en dispositivo (con la escala de animaciones del sistema en 1x); la salida de la pantalla de atrás sigue la duración de la entrante (límite de go_router); los pasos de Signup comparten una sola ruta, no una ruta por paso como el original.

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
- [ ] **Validar App Status con Remote Config** (hallazgo 2026-10-02, aplazado). En un teléfono real la app mostró
      una pantalla roja "Mantenimiento" con `status: "operational"` en el JSON: era `force_update` (ícono de
      actualización), porque el build instalado era `1` (`version: 1.0.0+1`) y `min_version_code` era mayor; al poner
      `min_version_code` en 0 la app abrió normal. Lo que hay que revisar contra el Kotlin
      (`RemoteConfigRepositoryImpl.checkAppStatus`):
      1. `force_update` usa `title`/`message` **del JSON**; el Kotlin usa textos fijos ("Hay una nueva actualización" /
         "Tienes una versión antigua…"). Por eso un título "Mantenimiento" confunde al usuario.
      2. `toAppStatus` también acepta `server_error` desde Remote Config; el Kotlin solo lee `maintenance`.
      3. El Kotlin ejecuta `clearStatus()` cuando el status no es `maintenance` (salvo `SERVER_ERROR`); Flutter solo lee
         Remote Config una vez en `bootstrap` y descarta `operational` sin limpiar.
      4. `min_version_code` se compara contra el build del `pubspec.yaml`, que ya va en `2.0.0+53` (> `versionCode 48` de Play).
      5. No hay tests de `RemoteConfigService.toAppStatus` (operational / maintenance / `dismissible` / `min_version_code`).
      Jira: tarea "Validar App Status con Remote Config", etiqueta `Centralizacion-Flutter`.
- [~] **GitHub Actions**: `ci.yml` (analyze + test en PRs a `develop`/`main`) y `release-internal.yml` (AAB
      firmado publicado en la **pista interna de Play** en cada push a `main`, con guarda de `versionCode`; sustituye
      a `release-apk.yml`); ver [`CI_CD.md`](CI_CD.md) y [`release/CONFIGURAR_PLAY_CI.md`](release/CONFIGURAR_PLAY_CI.md).
      Versión `2.0.0+53` (Play iba en 52 / 1.5.0). **Pendiente:** primera publicación real, flavor `manizales`,
      iOS (Codemagic, manual).
- [x] **Override del servidor de pruebas** (`--dart-define=USE_DEV_SERVER=true`, solo Android debug) para
      probar la API nueva antes de producción; marca "API DEV" y cleartext limitado a `192.168.20.198` en el
      source set `debug`. Ver BACKEND §2. Pendiente: binding HTTPS en el IIS de pruebas para iOS.
- [x] **Multi-tenant Fase 4 (cabeceras)**: `X-App-Id` / `X-App-Version` / `X-Platform` hacia la API Centralízate
      (`TenantHeadersInterceptor`), ruta real de `sync-status`, endpoints inexistentes eliminados y DTOs del
      municipio tolerantes a nulos (`phone` como string). Ver BACKEND §1.2, §3.10, §4.1.
- [x] **Historial siempre fresco y registro del pago antes de la pasarela** (2026-10-14): `historyPayNotifierProvider`
      es `autoDispose` y observa solo el id de la sesión (el pago nuevo aparece sin refrescar a mano; otro usuario ve
      su lista). "Pagar por PSE" **espera** `POST api/PaymentHistory/` y luego pide la transacción (antes iban a la
      vez y la transacción salía primero); el registro sigue siendo best-effort pero deja un no fatal en Crashlytics
      (`registerPaymentHistory`, sin datos personales). El log HTTP de debug ya no imprime el body del login ni las
      respuestas de cuenta (`DebugHttpLogInterceptor`).
- [ ] **API: `sync-status` responde 500 con estados de la pasarela que no están en `Availibity`** (visto en pruebas el
      2026-10-14 tras cancelar en la pasarela). Solo APROBADA/COMENZADA/FALLIDA/EXPIRADA existen; la app no se
      bloquea por ese 500 (opt-out de prompt 03), pero el pago no se actualiza a demanda. Lado API (en pausa).
- [ ] **API: exponer la hora del intento de pago en el Historial.** `paymentDate` es `DateOnly` (solo el día, y con
      la fecha del celular); la hora real está en `CreatedAt` (UTC) pero `PaymentHistoryUserListDto` no la incluye.
      Mientras tanto la app muestra solo la fecha (antes inventaba "12:00 AM"). Lado API (en pausa).
- [ ] **Quitar el guardado de `auth_token`**: guarda el mensaje "Inicio de sesión exitoso" (la API no emite
      token) y nada lo lee.
- [x] **Historial vacío = error** (`DioException [unknown]: null`): con 0 pagos, `GET api/PaymentHistory/User/{id}`
      responde 404 con un envelope y el cliente esperaba una lista. Se lee con `paymentHistoryFromResponse`; además
      `PaymentHistoryDTO` tolera nulos. Corregido también: refrescar sincronizaba FALLIDA en vez de COMENZADA.
- [ ] **Un test golpea la API real** (`GET /api/Department` devuelve 400 en la suite). Debe usar mock.

## Paridad de diálogos con Kotlin (2026-10-14) — `FRONTEND.md §5.15.1`

- [x] **Ports corregidos** (`ConfirmationDialog`, `ImportantAlertDialog`): glifo de 50 dentro del círculo
      de 60 (estaba en 44/40), botón relleno sin elevación, tipografía de `Type.kt` (títulos en negrita,
      botones `headlineSmall`/`headlineMedium`) vía `core/widgets/dialog_typography.dart`. Todos los diálogos
      que los usan heredan el arreglo.
- [x] **Aviso de sitio externo** (faltaba): `PendingUrl(url, showWarning)` en `MainUiState.urlToOpen`;
      "Aviso Importante" + "redirigiendo..." 3 s, no cancelable, para `AbrirUrl`/`AbrirUrlDirecto`/URL tras
      el ModalForm. Noticias, portal, términos y WhatsApp de pánico abren directo.
- [x] **Cambio de municipio** (menú lateral y Configuración) con `ConfirmationDialog`. El del menú ya no se
      abre desde `build()` (`addPostFrameCallback`), sino por `ref.listen`.
- [x] **Login**: "Inicio de sesión exitoso" sin botones y con cierre automático (2 s / 1,5 s en
      Configuración); "No se pudo iniciar sesión" en `ImportantAlertDialog` (2 s); error de Google → aviso
      3,2 s y registro, como `fallbackToRegister`. Se quitó `MainUiState.showLoginSuccessDialog`: tampoco
      hay nada en Kotlin que lo ponga en `true` (código muerto en ambos).
- [x] **Auditoría de `AlertDialog` crudos**: eliminar cuenta → `ImportantAlertDialog`; registro, PQRD
      (resultado y Habeas Data) y Ayuda siguen en `AlertDialog` M3 porque su original Kotlin también lo es
      (alineados en copy, botones y tipografía).
- [x] **Habeas Data en PQRSDF** (pedido de producto, 2026-10-14): tarjeta → aviso con el enlace tocable
      `funcionpublica.gov.co/…norma_pdf.php?i=49981` (Ley 1581) → "Cancelar" / "Continuar" a todo el ancho,
      separados 5 px; "Continuar" abre el formulario de la tarjeta tocada. Ya no repite los botones de tipo
      de PQRSDF. Test: `test/features/pqrd/pqrds_choice_habeas_data_test.dart`.
- [x] **Guardas**: `test/core/dialog_parity_test.dart` (falla con un `AlertDialog(` nuevo en
      `lib/features/`), `test/core/widgets/brand_dialogs_test.dart`,
      `test/features/home/external_link_dialog_test.dart`, `login_review_hook_test.dart` ampliado.
- [ ] **QA en dispositivo** Android + simulador iOS y capturas lado a lado con Kotlin (ver PR).

## PQRSDF con identificación — selects preseleccionados (2026-10-14)

Pedido de producto (el Kotlin no lo hace): al entrar, los selects ya traen un valor para no abrir uno por
uno los ~20. Solo se llenan campos vacíos (no pisa lo elegido ni el autollenado de la sesión).
`PqrdFormStateNotifier.applyIdentificationDefaults`.

- [x] **Paso 1**: primera opción de cada lista (Queja, De interés general, Persona natural, NO, Correo
      electrónico) **menos la Secretaría**, que decide a qué dependencia llega la PQRD y la elige el usuario.
- [x] **Paso 2**: tipo de documento (primera opción) y solo los opcionales con opción neutra ("NO" /
      "No Tiene", buscada por texto). Género, rango de edad, actividad, estrato, escolaridad y
      vulnerabilidad quedan vacíos: su primera opción es un dato real ("Masculino", "Primera Infancia
      (0-5 años)"…) que se radicaría como cierto.
- [x] **Paso 3**: departamento y ciudad **del municipio de la app**, buscados por nombre sin tildes ni
      mayúsculas (la primera opción del catálogo es Antioquia / Medellín para todos).
- [x] Bug de paso: cambiar de departamento no borraba la ciudad (`copyWith(ciudad: null)` con `??`); ahora
      `clearCiudad`. Test: `test/features/pqrd/pqrd_identification_defaults_test.dart`.
- [x] **`AtencionEspecial` al radicar** (aprobado 2026-10-14): era `atencionPreferencial != null`, siempre
      `true` porque el select es obligatorio (y ahora viene en "NO"); el Kotlin manda siempre `false`
      (`// Reemplaza con el valor real`, nunca completado). Ahora `true` solo si la opción elegida no es "NO".
      `IDAtencionPreferencial` / `IDAtencionEspecial` no cambian. **Confirmar con quien mantiene la API de
      trámites** si el backend usa este booleano.
- [x] "Quitar archivo" no borraba el adjunto (`copyWith(nombreArchivo: null, …)`, mismo patrón `??`): el
      botón no hacía nada: el archivo seguía en pantalla y se radicaba con él. Ahora `clearArchivo`, en la
      PQRD anónima y en la de identificación.

## Trámites por identidad: `code` / `kind` / `externalId` (prompt 09, 2026-10-15) — `FRONTEND.md §6`

El API sirve (prompt 08, desplegado en desarrollo) `code`, `kind` y `externalId` por trámite; `Procedures.Id`
deja de decidir comportamiento porque cambia entre entornos (en desarrollo el 9 es *Contribución al turismo*).

- [x] **Modelo** `Procedures` con `code`, `kind`, `externalId`, `gatewayTaxId` opcionales y lectura tolerante
      (tipo inesperado → `null`, nunca rompe).
- [x] **Resolver único** `lib/features/tramites/domain/procedure_identity.dart` (`ProcedureKind`,
      `resolveProcedure`): identidad del API cuando la respuesta la trae; tabla legacy 1–14 **solo** si ningún
      trámite trae `kind`; en una respuesta mixta, los que no traen `kind` se ocultan. Es el único lugar que
      conoce los ids 1–14. Id de pasarela: `gatewayTaxId ?? 43/26/269/20 por code`.
- [x] **Motor de trámites** por `kind`/`code`: pánico/cursos/escenarios por tipo aunque el valor sea `http`;
      valor `http(s)` → enlace (solo `TAX` pide el formulario de datos, el resto `AbrirUrlDirecto`); un
      certificado nunca cae en la consulta de impuestos; `OTHER` sin URL y `kind` desconocido → ocultos. Se
      quitaron `findUrl("Predial")`… y `contains("pánico")`.
- [x] **Duplicados por `key` estable** (`code`, `CURSOS` / `RESERVA_ESPACIOS`, `social:{id}`), no por
      `idtramite`: el certificado de turismo (id 9 en desarrollo) y el tile de Reservas conviven.
- [x] **Cruce con apidatamovil** por `externalId` (`findTaxProcedureByExternalId`) en el resultado de la
      consulta y en el PSV; el historial sigue mandando `MunicipalityProcedure.id` de la fila.
- [x] **Entrada a certificados** con `CertificateProcedure` por `extra` (ruta `/municipality/:id/certificados`):
      título/ícono por `code`, `IDTramite = externalId`, `IDImpuesto` del resolver, precio por edad si
      `CERT_TURISMO`. Certificado sin id de pasarela (p. ej. `CERT_TEST` en desarrollo) → oculto con log en debug.
- [x] Tests: `procedure_identity_test.dart`, `tramite_engine_test.dart` (catálogo con ids recreados 230–243 =
      mismas acciones que 1–14).
- [ ] **QA manual contra el servidor de pruebas** (municipio 81): ver notas del PR.
- [ ] **Portar a la base Santander** en su propio prompt cuando ese repo esté limpio.
- [~] Bug previo encontrado (no es de este cambio): certificados y servicios públicos empujan
      `extra: {'url': …}` a `pagosProcessing`, que lee `'paymentUrl'` → la pasarela abre con URL vacía.
      **Certificados corregido en el prompt 07**; servicios públicos sigue pendiente.

## Certificados — paridad con Kotlin, adjunto real y historial (prompt 07, 2026-10-15) — `FRONTEND.md §5.7`

- [x] **A1** La pasarela nunca abría (`'url'` vs `'paymentUrl'`): ahora `AppRoutes.pagosProcessingExtra(url)`.
- [x] **A2** `copyWith` con banderas `clearX` (errores, adjunto, URL): el error de identificación se va al
      corregirla y "Quitar archivo" funciona.
- [x] **A3** Autollenado: tipo de documento por descripción normalizada; sin coincidencia queda vacío.
- [x] **A4** Estado del envío dentro del notifier `autoDispose.family` (no global).
- [x] **A5** Regla de visibilidad en `isCertificateOffered` (turismo siempre, el resto con valor). La codificación
      del valor en la ruta ya no aplica: desde el prompt 09 viaja por `extra`.
- [x] **Parte B** Validaciones y textos de Kotlin, correo con el patrón compartido, teclado por tipo de documento,
      precio de turismo, adjunto real (5 MB, pdf/png/jpg, lectura en `Isolate`), orden y textos del envío, sin
      doble envío.
- [x] **Parte C** Registro en el historial antes de `CrearTransaccion` (best-effort, no fatal) y pantalla de
      procesamiento completa. Verificado contra `PaymentHistoryService`/`BancolombiaPseService` del API.
- [x] **Parte D** UI medida contra los `.kt` (campos, botones dentro del scroll, resumen, aviso, adjunto).
- [x] Tests: `test/features/certificados/certificates_notifier_test.dart`,
      `certificates_payment_extra_test.dart`; `tramite_engine_test.dart` ampliado.
- [x] **`Estado` booleano de `tramitesservices`** (encontrado en QA): `ProcedureApplicationResponse.estado` era
      `String` como en Kotlin (Gson convierte `true` en `"true"`); en Dart `as String` fallaba al finalizar. Ahora es
      `bool` con lectura tolerante (`true` o `"true"`), igual que `ResponsePQRD`.
- [x] **QA en dispositivo** contra el servidor de pruebas (Brayan, 2026-10-16): flujo completo hasta la pasarela.
      Con el municipio de pruebas 81 la pasarela respondía "No se pudo crear la transacción…" porque su código de
      entidad era de relleno (`321321321`) y la pasarela es la de producción; con un código de entidad real pasa.
- [ ] El contenedor redondeado lo pone `TopBarNavigationScaffold` (radio 16, sin el desplazamiento de 10 del
      Kotlin, que usa 18): se dejó así porque lo comparten 5 pantallas.

## Release hardening — navegación (backport de Santander `d553eff`, 2026-10-13)

Port a mano (los repos divergieron el 2026-08-21) de la parte de navegación de `d553eff`. Cada punto
tiene tests que fallan con el código anterior.

- [x] **El estado bloqueante ya no desmonta el router.** `GlobalStatusOverlay` (`lib/app.dart`) pinta
      `_BlockingStatusScreen` *encima* del router (capa superior del `Stack`, con barrera, `ExcludeFocus` y
      `_BackBlocker`) en vez de sustituirlo. Un 5xx / mantenimiento / force update ya no borra formularios,
      pasos ni scroll. Prioridad: bloqueante > diálogo sin conexión > contenido.
- [x] **Diálogos de la Home por `ref.listen`.** "Próximamente" y "Salir" se lanzaban desde `build()` y se
      apilaban 2-5 copias; "Sí, salir" podía navegar varias veces (vuelta intermitente a Welcome). Ahora salen
      una vez por transición `false → true` y el flag se resetea si se cierran con el gesto Atrás.
- [x] **`errorBuilder` de go_router** con `_RouteErrorScreen` ("No pudimos abrir esta pantalla." +
      "Volver al inicio" → `computeStartDestination`), sin redirección automática.
- [x] **`SafePop`** (`lib/core/router/safe_pop.dart`, `popOrGo`). Pago → "Verificar estado" reconstruye la
      pila Home → Historial; `TopBarNavigationScaffold` con `onBack` por defecto cae a la Home del municipio
      (`:id`) si la pantalla es la única de la pila, también con el Atrás del sistema. PQRD y Certificados
      usan `popOrGo` en vez de `context.pop()`.
- [ ] **Verificación manual en dispositivo Android** de los 4 escenarios (ver PR).

## Fase 5 — Ajuste iOS 🍎

> ⚠️ **iOS está como lo dejó `flutter create`.** `ios/Runner/Info.plist` conserva la fecha de creación
> del proyecto y solo las claves de plantilla; solo existe `Runner.xcscheme`. El código Dart sí es
> multiplataforma y las 6 base URLs son HTTPS (sin bloqueo de ATS), así que el trabajo es de
> configuración nativa, no de migración. **Requiere un Mac y la cuenta de Apple Developer.**

- [x] **`NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription` en `Info.plist`** (2026-10-19). Sin la
      cámara, `mobile_scanner` crashea al abrir el escáner; y el texto se exige por el código enlazado (ITMS-90683),
      aunque el módulo de servicios públicos esté desactivado en backend. `file_picker` exige la de galería.
- [x] **App iOS registrada en Firebase** (`1:577349260806:ios:c70540fa…`, 2026-10-19) y opciones `ios` en
      `firebase_options_municipios.dart`: ya no lanza `UnsupportedError` al arrancar. El `GoogleService-Info.plist`
      no se versiona ni se empaqueta (igual que `google-services.json`); Firebase se inicializa con las opciones Dart.
- [x] **Bundle ID iOS = `com.tramites1cero1.centralizacion`** (2026-10-19, mismo de Android; no había app previa en la App Store).
      En `project.pbxproj` (Runner y RunnerTests). Falta registrarlo en Apple Developer **con Push Notifications marcada
      antes de generar el perfil** (si no, el perfil sale sin `aps-environment` y la subida falla).
- [x] Solo iPhone (`TARGETED_DEVICE_FAMILY = 1`): la app es vertical; con iPad Apple exige las 4 orientaciones (error 90474 en 101 Fintech).
- [x] Push: `Runner.entitlements` con `aps-environment` y `UIBackgroundModes` → `remote-notification` en `Info.plist`.
- [ ] Resto de permisos en `Info.plist` (ubicación, notificaciones)
- [ ] Schemes/configs por flavor en Xcode
- [~] `GoogleService-Info.plist` por flavor — `municipios` listo (copia local, ignorada por git); `manizales` pendiente
- [ ] APNs Auth Key (.p8) en Firebase para FCM — **sin ella no llegan push a iOS** (paso de consola)
- [x] Google Sign-In en `Info.plist`: `GIDClientID`, `GIDServerClientID` (cliente web) y `REVERSED_CLIENT_ID` como URL scheme
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
