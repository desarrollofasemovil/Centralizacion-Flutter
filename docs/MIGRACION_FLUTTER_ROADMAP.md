# Roadmap de migración — checklist accionable

> Lista viva de tareas. **Marca cada casilla `[x]` al completarla.** El orden importa: las fases de abajo dependen del núcleo de arriba. Módulos tomados del catálogo de `MIGRACION_FLUTTER_FRONTEND.md §5`.

Leyenda: ⚙️ infraestructura · 🤖 automatizable con agente · 🍎 requiere atención iOS · 🟦 requerido por Manizales

---

## Fase 0 — Setup del proyecto Flutter ⚙️

- [ ] Crear proyecto Flutter (`trami_flutter`) con soporte iOS + Android
- [ ] `applicationId` / `bundleId` = `com.tramites1cero1.centralizacion`
- [ ] Estructura de carpetas según `CONVENCIONES.md` (`core/`, `features/`, `flavors/`)
- [ ] `pubspec.yaml` con dependencias del stack (dio, retrofit, riverpod, go_router, json_serializable/freezed, firebase_*, mobile_scanner, cached_network_image, etc.)
- [ ] Configurar `build_runner` + `json_serializable`
- [ ] Scaffold de flavors `municipios` y `manizales` (ver `FLAVORS.md`) — solo el `municipios` se desarrolla por ahora
- [ ] FlutterFire: `firebase_options_municipios.dart` apuntando al proyecto Firebase actual
- [ ] Copiar `CLAUDE.md` y los `MIGRACION_FLUTTER_*.md` a la raíz del proyecto Flutter
- [ ] GitHub Actions: build APK + IPA por flavor (mac-runner)
- [ ] **Iniciar Apple Developer Account** (proceso externo, puede tardar hasta 2 semanas) 🍎

## Fase 1 — Núcleo (core) ⚙️

- [ ] Cliente Dio único + `BaseOptions` (timeouts 40s) — `BACKEND.md §1`
- [ ] Interceptor global de errores (equivalente a `GlobalErrorInterceptor`) → estado global de app
- [ ] Factory de servicios por base URL (las 6 de `BACKEND.md §2`)
- [ ] 🤖 Traducir DTOs Kotlin → Dart con el agente `migration-agent/` — `BACKEND.md §4`
- [ ] Servicios Retrofit por microservicio (Auth, Municipality, Tax, PQRD, Generales, etc.)
- [ ] Persistencia local (DataStore → shared_preferences/Hive): sesión de usuario, ubicación guardada, tema
- [ ] Estado global de app (`AppStatusManager` → provider Riverpod): operational/maintenance/force_update/server_error
- [ ] FlutterFire: Crashlytics, Analytics, Remote Config, Messaging
- [ ] Remote Config con las 4 keys: `welcome_carousel_images`, `app_status_config`, `send_to_welcome`, `tourism_tax_rates` — `BACKEND.md §6.1`
- [ ] Theming dinámico desde backend (`Theme` hex → `ThemeData`) — `FRONTEND.md §4`
- [ ] Navegación con go_router (equivalente a los grafos anidados) — `FRONTEND.md §2`
- [ ] Lógica de arranque / `startDestination` (welcome vs municipio guardado) — `FRONTEND.md §1.1`

## Fase 2 — Onboarding, sesión y home

- [ ] Splash + Welcome + carrusel de anuncios
- [ ] Login nativo (correo/clave) contra la API — `BACKEND.md §5.1`
- [ ] Login con Google (Firebase Auth + google_sign_in) — `BACKEND.md §5.2` 🍎
- [ ] Registro en 3 pasos (con borrador/draft y prellenado desde Google)
- [ ] Recuperación de contraseña
- [ ] Selector de municipio (solo flavor `municipios`)
- [ ] MainScreen: bottom nav + header (escudo + nombre) + side menu
- [ ] Notificaciones push (FCM) + notificaciones locales + canales 🍎
- [ ] Módulo Noticias

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
