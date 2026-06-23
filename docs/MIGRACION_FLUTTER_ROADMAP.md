# Roadmap de migración — checklist accionable

> Lista viva de tareas. **Marca cada casilla `[x]` al completarla.** El orden importa: las fases de abajo dependen del núcleo de arriba. Módulos tomados del catálogo de `MIGRACION_FLUTTER_FRONTEND.md §5`.

Leyenda: ⚙️ infraestructura · 🤖 automatizable con agente · 🍎 requiere atención iOS · 🟦 requerido por Manizales

---

## Fase 0 — Setup del proyecto Flutter ⚙️

- [x] Crear proyecto Flutter (`tramiapp_flutter`) con soporte iOS + Android
- [x] `applicationId` = `com.tramites1cero1.centralizacion` (Android; `bundleId` iOS en Fase 5)
- [x] Estructura de carpetas según `CONVENCIONES.md` (`core/`, `features/`, `flavors/`)
- [x] `pubspec.yaml` con dependencias del stack (dio, retrofit, riverpod, go_router, json_serializable, firebase_*, mobile_scanner, cached_network_image, etc.) — `flutter_inappwebview` pospuesto (incompatible con AGP 9; se reañade cuando haya versión compatible o vía `url_launcher`)
- [x] Configurar `build_runner` + `json_serializable` (verificado con `shield_dto`)
- [x] Scaffold de flavors `municipios` y `manizales` (ver `FLAVORS.md`) — solo el `municipios` se desarrolla por ahora
- [x] FlutterFire: `firebase_options_municipios.dart` apuntando al proyecto Firebase actual (`betaappcentralizate`, Android; iOS pendiente)
- [x] Copiar `CLAUDE.md` y los `MIGRACION_FLUTTER_*.md` a la raíz del proyecto Flutter (ya viven en `tramiapp_flutter/` y `tramiapp_flutter/docs/`)
- [ ] GitHub Actions: build APK + IPA por flavor (mac-runner)
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

## Fase 3 — Módulos core

- [ ] Trámites + motor de decisión `toInfoTramite`/`toDomainModel` (portar con tests) — `FRONTEND.md §6`
- [ ] PQRD (anónima + identificada, 3 pasos; catálogos por `CodigoEntidad`)
- [ ] Impuestos (consulta dinámica por `queryFields` + respuesta + descarga PDF) 🍎
- [ ] Certificados (3 pasos)
- [ ] Servicios Públicos + escáner QR/barcode (`mobile_scanner`) 🍎
- [ ] Pagos: PSV + PaymentProcessing (pasarela) + estado de transacción
- [ ] Historial de pagos

## Fase 4 — Módulos de Manizales + perfil

- [ ] 🟦 Cursos (`CourseRepository` → Flutter)
- [ ] 🟦 Escenarios deportivos (`VenueRepository` → Flutter, reserva + email)
- [ ] Recordatorios + calendario
- [ ] Soporte / Ayuda (formulario → email)
- [ ] Editar perfil + configuración de usuario + cambio de contraseña

## Fase 5 — Ajuste iOS 🍎

- [ ] Schemes/configs por flavor en Xcode
- [ ] APNs Auth Key (.p8) en Firebase para FCM
- [ ] Permisos en `Info.plist` (cámara, ubicación, notificaciones)
- [ ] `REVERSED_CLIENT_ID` para Google Sign-In
- [ ] Descarga de PDFs sin DownloadManager (`dio` + `open_filex`)
- [ ] Safe Area / home indicator en layouts con bottom nav
- [ ] Pruebas en iPhone físico → TestFlight

## Fase 6 — QA y publicación de Centralización

- [ ] QA funcional completo iOS + Android
- [ ] Rendimiento (Firebase Performance + Crashlytics)
- [ ] Revisión App Store Guidelines
- [ ] Publicar en Play Store y App Store

## Fase 7 — Trami App Manizales (flavor) 🟦

> Solo después de terminar Centralización. Seguir el playbook de `FLAVORS.md §11`.

- [ ] Confirmar `id` y `entityCode` de Manizales en el backend
- [ ] Proyecto Firebase de Manizales (apps iOS+Android, APNs, 4 keys RC, Google Auth)
- [ ] `flavors.dart` + `main_manizales.dart`
- [ ] productFlavor Android + scheme iOS (flavorizr)
- [ ] `google-services.json` / `GoogleService-Info.plist` en sus carpetas
- [ ] Ícono, nombre y colores de la Alcaldía de Manizales
- [ ] Bundle id + Provisioning Profile en Apple Developer
- [ ] Build + publicar en Play Store y App Store (cuenta empresa)
- [ ] Documentar el playbook validado para los siguientes municipios
