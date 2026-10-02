# In-App Update (Play Core) — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Forzar la actualización inmediata de Google Play cuando hay una versión nueva y reanudarla si quedó a medias, igual que `MainActivity.kt`.

**Architecture:** `InAppUpdateService` en `core/update/` con la lógica (cuándo iniciar y cuándo reanudar) sobre un `PlayUpdateGateway` abstracto que envuelve `in_app_update`. Un observer de ciclo de vida llama a `onResume()`; `bootstrap` ejecuta `checkOnStart()` sin bloquear el arranque. **Solo Android.**

**Tech Stack:** `in_app_update` ^5.0.0 (resolvió 5.0.0 el 2026-10-02), `flutter_riverpod` 3.

**Spec (Kotlin en `codebase/app/src/main/java/com/tramites1cero1/centralizacion/`):** `MainActivity.kt`: `onCreate` (líneas 112-118), `checkForAppUpdate()` (251-270) y `onResume()` (272-285).

## Global Constraints

- Rama desde `develop` (`feature/in-app-update`); PR contra `develop` (confirmar antes de abrirlo).
- `flutter analyze` en 0 issues, `flutter test` en verde; build release local antes del PR: `flutter build apk --release --flavor municipios -t lib/main_municipios.dart`.
- Solo tipo **IMMEDIATE** (no flexible). Se inicia si hay actualización disponible **y** el tipo inmediato está permitido.
- Habilitado solo en Android y fuera de web: `!kIsWeb && defaultTargetPlatform == TargetPlatform.android`. En iOS/web/escritorio el servicio es un no-op que no toca el gateway.
- Los errores se registran con `debugPrint` y se tragan (Kotlin: `Log.e`); nunca deben impedir el arranque.
- **No sustituye** al `force_update` de Remote Config (`core/remote_config`): ambos conviven sin tocarse.
- No añadir lógica por flavor: municipios y manizales se comportan igual.

## Review Focus

1. **App instalada fuera de Play** (APK a mano): `checkForUpdate()` falla; debe tragarse el error y la app arrancar normal. → Task 2.
2. **El usuario cancela la actualización inmediata:** no debe haber bucle; `onResume` con estado `available` **no** reinicia el flujo (solo reanuda `inProgress`). → Task 2.
3. **`resumed` re-entrante:** al cerrarse la UI de Play la app emite `resumed` mientras el flujo sigue activo; no debe abrirse un segundo flujo. → Task 2.
4. **Arranque en frío con una actualización a medias** (el proceso murió durante la descarga): en Android nativo el `onResume` posterior al `onCreate` la reanudaba; en Flutter no hay ese `resumed` inicial, así que `checkOnStart()` debe reanudar también `inProgress`. → Task 2.
5. **iOS/web/escritorio:** ninguna llamada al plugin (no existe `MethodChannel`). → Task 2.

---

### Task 1: Dependencia, verificación de compilación y de API

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`

**Interfaces:**
- Produces: `package:in_app_update/in_app_update.dart`.

- [ ] **Step 1: Añadir la dependencia**

Run: `flutter pub add in_app_update`
Expected: añade `in_app_update: ^5.0.0` (o la vigente).

- [ ] **Step 2: Confirmar la API de la versión resuelta**

Leer el README y el código del paquete en `.pub-cache` (o con `flutter pub deps`) y confirmar los nombres que usa este plan: `InAppUpdate.checkForUpdate()` → `AppUpdateInfo` con `updateAvailability` (valores `updateAvailable`, `developerTriggeredUpdateInProgress`) e `immediateUpdateAllowed`; `InAppUpdate.performImmediateUpdate()`. Si algo difiere, ajustar solo el gateway (Task 2); el resto del plan no cambia.

- [ ] **Step 3: Compilar el flavor**

Run: `flutter build apk --debug --flavor municipios -t lib/main_municipios.dart`
Expected: `Built build\app\outputs\flutter-apk\app-municipios-debug.apk`. Si falla por AGP 9/Gradle, parar y reportar.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add in_app_update"
```

---

### Task 2: Servicio y gateway

**Files:**
- Create: `lib/core/update/play_update_gateway.dart`
- Create: `lib/core/update/in_app_update_service.dart`
- Test: `test/core/update/in_app_update_service_test.dart`

**Interfaces:**
- Consumes: `InAppUpdate` del plugin (Task 1).
- Produces:
  - `enum PlayUpdateState { none, available, inProgress }`
  - `abstract class PlayUpdateGateway { Future<PlayUpdateState> check(); Future<void> startImmediate(); }`
  - `class InAppUpdateGateway implements PlayUpdateGateway` — `check()` devuelve `available` solo si `updateAvailability == updateAvailable && immediateUpdateAllowed`, `inProgress` si `developerTriggeredUpdateInProgress`, `none` en otro caso; `startImmediate()` llama `performImmediateUpdate()`.
  - `class InAppUpdateService { InAppUpdateService(PlayUpdateGateway gateway, {required bool enabled}); Future<void> checkOnStart(); Future<void> onResume(); }`
  - `final inAppUpdateServiceProvider = Provider<InAppUpdateService>(...)`

Reglas: `checkOnStart()` inicia el flujo si el estado es `available` **o** `inProgress`; `onResume()` solo si es `inProgress`; ambos ignoran la llamada si ya hay un flujo en curso (guardia `_busy`); ambos envuelven `check()` y `startImmediate()` en `try/catch` con `debugPrint`; con `enabled == false` retornan sin tocar el gateway.

- [ ] **Step 1: Escribir los tests que fallan**

Con un `_FakeGateway` (estado configurable, cuenta `startImmediate`, puede lanzar o quedar pendiente con un `Completer`):

```dart
test('checkOnStart con available inicia el flujo una vez', ...);
test('checkOnStart sin actualización no inicia nada', ...);
test('checkOnStart con inProgress lo reanuda (arranque en frío con descarga a medias)', ...);
test('onResume con inProgress lo reanuda', ...);
test('onResume con available NO inicia el flujo (sin bucle tras cancelar)', ...);
test('check() lanza (app fuera de Play): se traga el error y no inicia', ...);
test('startImmediate lanza (usuario cancela): se traga el error', ...);
test('onResume durante un flujo activo no abre un segundo flujo', ...);   // Completer pendiente + segunda llamada => startImmediate == 1
test('enabled == false: no llama al gateway', ...);
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/core/update/in_app_update_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar** gateway y servicio con las reglas de arriba. `enabled` por defecto en el provider: `!kIsWeb && defaultTargetPlatform == TargetPlatform.android`.

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test test/core/update/in_app_update_service_test.dart`
Expected: PASS (9 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/update test/core/update
git commit -m "feat(update): servicio de In-App Update inmediata de Play"
```

---

### Task 3: Ciclo de vida y arranque

**Files:**
- Modify: `lib/core/update/in_app_update_service.dart` (añadir el observer)
- Modify: `lib/bootstrap.dart` (tras `runApp`)
- Test: `test/core/update/in_app_update_lifecycle_test.dart`

**Interfaces:**
- Consumes: `InAppUpdateService` (Task 2).
- Produces: `class InAppUpdateLifecycleObserver with WidgetsBindingObserver { InAppUpdateLifecycleObserver(InAppUpdateService service); }` — en `AppLifecycleState.resumed` llama `service.onResume()`.

En `bootstrap`, después de `runApp(...)`: `WidgetsBinding.instance.addObserver(InAppUpdateLifecycleObserver(service))` y `unawaited(service.checkOnStart())`, con `service = container.read(inAppUpdateServiceProvider)`. **No** `await`: no debe retrasar el primer frame.

- [ ] **Step 1: Escribir el test que falla**

```dart
testWidgets('resumed llama onResume una vez; otros estados no', (tester) async {
  // servicio falso que cuenta onResume; tester.binding.addObserver(...);
  // tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused)  => 0
  // tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed) => 1
});
```

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/core/update/in_app_update_lifecycle_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar** el observer y la llamada en `bootstrap`.

- [ ] **Step 4: Suite completa**

Run: `flutter test`
Expected: toda la suite en verde.

- [ ] **Step 5: Commit**

```bash
git add lib/core/update lib/bootstrap.dart test/core/update
git commit -m "feat(update): comprobar actualización al arrancar y al volver a primer plano"
```

---

### Task 4: Verificación final, QA en Play y roadmap

**Files:**
- Modify: `docs/MIGRACION_FLUTTER_ROADMAP.md` (añadir línea `In-App Update (Play Core)` marcada `[x]` en código y nota de que la verificación en Play está pendiente)

- [ ] **Step 1:** `flutter analyze` → `No issues found!`.
- [ ] **Step 2:** `flutter test` → todos en verde.
- [ ] **Step 3:** `flutter build apk --release --flavor municipios -t lib/main_municipios.dart` → `Built ...app-municipios-release.apk` (valida R8 con Play Core).
- [ ] **Step 4: QA con un APK instalado a mano:** abrir la app. No debe haber excepciones ni pantallas nuevas (el chequeo falla en silencio fuera de Play); revisar `adb logcat`.
- [ ] **Step 5: QA real en Google Play (bloqueado hasta que exista la publicación).** Requiere: AAB subido a la pista interna con `versionCode` N, la app instalada desde Play, y luego una versión N+1 subida a la misma pista. Pasos: abrir la versión N → aparece la pantalla de actualización inmediata de Play; cancelar → la app sigue usable y no reaparece en el mismo arranque; volver a abrir → reaparece; completar → reinicia en N+1. **No cerrar el plan como verificado hasta hacerlo;** hasta entonces anotarlo en el PR como pendiente.
- [ ] **Step 6: Commit y PR** contra `develop`

```bash
git add docs/MIGRACION_FLUTTER_ROADMAP.md
git commit -m "docs(roadmap): In-App Update implementado (verificación en Play pendiente)"
```
