# Conectividad y NoConnectionDialog — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Detectar la pérdida de conexión y mostrar el diálogo bloqueante "No estás conectado a internet" como lo hacen `MainActivity` y `SplashScreen` del Kotlin original.

**Architecture:** Capa `core/connectivity` (observer abstracto sobre `connectivity_plus` expuesto con providers Riverpod), un `NoConnectionNotifier` (estado booleano con debounce de 3 s) y un widget `NoConnectionDialog` en `core/widgets/`. El diálogo se monta como overlay en `GlobalStatusOverlay` (`app.dart`) y el Splash consulta la conectividad antes de navegar.

**Tech Stack:** Flutter 3.44.0 / Dart ^3.12.0, `flutter_riverpod` 3 (`Notifier`, sin code-gen), `connectivity_plus` ^7.3.1 (resolvió 7.3.1 el 2026-10-02), `go_router`.

**Spec (fuente de verdad = Kotlin en `codebase/app/src/main/java/com/tramites1cero1/centralizacion/`):**
`data/network/ConnectivityObserver.kt`, `MainActivityViewModel.kt` (líneas 41-82 y 123), `MainActivity.kt` (`setContent`: prioridad de pantallas), `ui/components/NoConnectionDialog.kt`, `ui/screen/splash/SplashScreen.kt` (líneas 30-110). Contexto: `docs/MIGRACION_FLUTTER_FRONTEND.md §3` y la línea "NoConnectionDialog" del roadmap.

## Global Constraints

- Rama desde `develop` (`feature/conectividad-no-connection-dialog`); PR contra `develop`, no `main` (confirmar antes de abrirlo).
- `flutter analyze` en 0 issues y `flutter test` en verde. El CI exige el check `Analyze & test`.
- Build release local antes del PR: `flutter build apk --release --flavor municipios -t lib/main_municipios.dart`.
- Textos de UI en español y **exactos** a los del Kotlin (ver Task 4). Seguir `AppTheme`/`AppColors`; no crear barras superiores ni botones de atrás nuevos.
- Debounce **3000 ms** (Kotlin: `delay(3000)`), inyectable por provider para los tests.
- El diálogo no se puede descartar tocando fuera ni con "atrás" (Kotlin: `onDismissRequest = {}`).
- Prioridad de pantallas (FRONTEND §3): estado bloqueante global > diálogo sin conexión > contenido normal.
- Nada de `if (flavor == ...)`: el comportamiento es idéntico en los dos flavors.

## Review Focus

Entradas que el spec no menciona y que el usuario sí va a encontrar (cada una tiene su test en la tarea indicada):
1. **Intermitencia** (sin red → con red → sin red en pocos segundos): la ventana de 3 s se reinicia con cada pérdida; el diálogo no debe parpadear. → Task 3.
2. **Arranque sin red:** primera emisión `unavailable` debe mostrar el diálogo tras el debounce, y en el Splash de inmediato. → Tasks 3 y 6.
3. **Lista de resultados vacía o `[none]`** de `connectivity_plus` equivale a sin conexión; `[wifi, mobile]` es con conexión. → Task 2.
4. **Emisiones duplicadas** del plugin no deben reiniciar el debounce (el Kotlin usa `distinctUntilChanged`). → Task 2.
5. **Estado bloqueante activo** (`server_error`/`force_update`): el diálogo no debe aparecer encima. → Task 5.

---

### Task 1: Dependencia y verificación de compilación

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`

**Interfaces:**
- Produces: `package:connectivity_plus/connectivity_plus.dart` disponible para las tareas siguientes.

- [ ] **Step 1: Añadir la dependencia**

Run: `flutter pub add connectivity_plus`
Expected: añade `connectivity_plus: ^7.3.1` (o la resolución vigente) bajo `dependencies:`.

- [ ] **Step 2: Compilar el flavor para detectar incompatibilidades con AGP 9 / Gradle 8.14**

Run: `flutter build apk --debug --flavor municipios -t lib/main_municipios.dart`
Expected: `Built build\app\outputs\flutter-apk\app-municipios-debug.apk`. Si falla por el plugin, parar y reportar (antes se retiró `flutter_inappwebview` por el mismo motivo).

- [ ] **Step 3: Confirmar el permiso en el manifest fusionado**

Buscar `ACCESS_NETWORK_STATE` en el `AndroidManifest.xml` fusionado bajo `build/app/intermediates/merged_manifests/municipiosDebug/`. Debe aparecer (lo aporta el plugin); si no, añadirlo a `android/app/src/main/AndroidManifest.xml`.

- [ ] **Step 4: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add connectivity_plus"
```

---

### Task 2: Observer de conectividad

**Files:**
- Create: `lib/core/connectivity/connectivity_status.dart`
- Create: `lib/core/connectivity/connectivity_observer.dart`
- Test: `test/core/connectivity/connectivity_observer_test.dart`

**Interfaces:**
- Consumes: `Connectivity` de `connectivity_plus` (`checkConnectivity()` → `Future<List<ConnectivityResult>>`, `onConnectivityChanged` → `Stream<List<ConnectivityResult>>`).
- Produces:
  - `enum ConnectivityStatus { available, unavailable }`
  - `ConnectivityStatus statusFromResults(List<ConnectivityResult> results)`
  - `abstract class ConnectivityObserver { Stream<ConnectivityStatus> observe(); Future<ConnectivityStatus> current(); }`
  - `class PlatformConnectivityObserver implements ConnectivityObserver { PlatformConnectivityObserver(Connectivity connectivity); }`
  - `final connectivityObserverProvider = Provider<ConnectivityObserver>(...)`
  - `final connectivityStatusProvider = StreamProvider<ConnectivityStatus>(...)`

- [ ] **Step 1: Escribir los tests que fallan**

```dart
test('[wifi, mobile] => available', () =>
    expect(statusFromResults([ConnectivityResult.wifi, ConnectivityResult.mobile]), ConnectivityStatus.available));
test('[none] => unavailable', () =>
    expect(statusFromResults([ConnectivityResult.none]), ConnectivityStatus.unavailable));
test('[] => unavailable', () =>
    expect(statusFromResults(const []), ConnectivityStatus.unavailable));
test('observe(): estado inicial y cambios, sin duplicados consecutivos', () async {
  // _FakeConnectivity implements Connectivity: checkConnectivity() => [wifi];
  // onConnectivityChanged emite [wifi], [none], [none], [mobile].
  final emitted = await PlatformConnectivityObserver(fake).observe().take(3).toList();
  expect(emitted, [ConnectivityStatus.available, ConnectivityStatus.unavailable, ConnectivityStatus.available]);
});
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/core/connectivity/connectivity_observer_test.dart`
Expected: FAIL (símbolos no definidos).

- [ ] **Step 3: Implementar `connectivity_status.dart` y `connectivity_observer.dart`**

`observe()` emite primero `current()` y luego `onConnectivityChanged.map(statusFromResults)`, todo con `.distinct()` (equivale al `distinctUntilChanged()` del Kotlin). `statusFromResults` devuelve `unavailable` si la lista está vacía o solo contiene `ConnectivityResult.none`. `connectivityObserverProvider` crea `PlatformConnectivityObserver(Connectivity())`; `connectivityStatusProvider` es `StreamProvider` sobre `observe()`.

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test test/core/connectivity/connectivity_observer_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/connectivity test/core/connectivity
git commit -m "feat(connectivity): observer sobre connectivity_plus"
```

---

### Task 3: Notifier del diálogo con debounce

**Files:**
- Create: `lib/core/connectivity/no_connection_notifier.dart`
- Test: `test/core/connectivity/no_connection_notifier_test.dart`

**Interfaces:**
- Consumes: `connectivityStatusProvider`, `connectivityObserverProvider` (Task 2).
- Produces:
  - `final noConnectionDebounceProvider = Provider<Duration>((_) => const Duration(seconds: 3))`
  - `class NoConnectionNotifier extends Notifier<bool>` con `void show()` y `void dismiss()`
  - `final noConnectionDialogProvider = NotifierProvider<NoConnectionNotifier, bool>(NoConnectionNotifier.new)`

Reglas (port de `MainActivityViewModel.kt:62-83`): cada emisión cancela el temporizador pendiente; `available` → `state = false` de inmediato; `unavailable` con el diálogo oculto → programar `state = true` tras el debounce; `unavailable` con el diálogo ya visible → no hacer nada. Cancelar el temporizador en `ref.onDispose`.

- [ ] **Step 1: Escribir los tests que fallan**

Usar `ProviderContainer` con `noConnectionDebounceProvider` sobreescrito a `Duration(milliseconds: 20)` y un `connectivityObserverProvider` falso respaldado por un `StreamController<ConnectivityStatus>`. Esperas con `await Future<void>.delayed(const Duration(milliseconds: 60))`.

```dart
test('sin conexión sostenida muestra el diálogo solo tras el debounce');   // false al instante, true a los 60 ms
test('recuperar la red antes del debounce cancela la aparición');            // unavailable, available a 5 ms => sigue false
test('intermitencia reinicia la ventana');                                   // unavailable, available, unavailable => true solo 20 ms después de la última pérdida
test('available con el diálogo visible lo oculta de inmediato');
test('arranque sin red (primera emisión unavailable) muestra el diálogo');
test('show() lo muestra sin debounce y dismiss() lo oculta');
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/core/connectivity/no_connection_notifier_test.dart`
Expected: FAIL (símbolos no definidos).

- [ ] **Step 3: Implementar `NoConnectionNotifier`**

`build()` retorna `false` y se suscribe con `ref.listen(connectivityStatusProvider, ..., fireImmediately: true)`; el `Timer` se guarda en un campo y se cancela en cada emisión y en `ref.onDispose`.

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test test/core/connectivity/no_connection_notifier_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/connectivity/no_connection_notifier.dart test/core/connectivity/no_connection_notifier_test.dart
git commit -m "feat(connectivity): notifier del diálogo sin conexión con debounce de 3 s"
```

---

### Task 4: Widget `NoConnectionDialog` y asset

**Files:**
- Create: `assets/images/icon_no_wifi.png` (copiar de `codebase/app/src/main/res/drawable/icon_no_wifi.png`; `pubspec.yaml` ya declara `assets/images/`)
- Create: `lib/core/widgets/no_connection_dialog.dart`
- Test: `test/core/widgets/no_connection_dialog_test.dart`

**Interfaces:**
- Produces: `class NoConnectionDialog extends StatelessWidget { const NoConnectionDialog({required bool isConnectionRestored, required VoidCallback onDismiss, super.key}); }`

Diseño (de `NoConnectionDialog.kt`): `Card` con radio 16 y color `colorScheme.surface`; `Column` centrada con padding 24 y separación 16; imagen 90×90; título "No estás conectado a internet" (titleLarge, bold, centrado); cuerpo "Señor(a) ciudadano. Para un correcto funcionamiento de nuestra App es necesario estar conectado a internet, por favor verifique su conexión y vuelva a intentarlo." (bodyMedium, centrado); botón de ancho completo "Entendido" habilitado solo si `isConnectionRestored`.

- [ ] **Step 1: Escribir los tests que fallan**

```dart
testWidgets('muestra título, cuerpo y botón con los textos exactos del Kotlin');
testWidgets('el botón "Entendido" está deshabilitado si no hay conexión restaurada');   // tester.widget<FilledButton>(...).onPressed == null
testWidgets('con conexión restaurada, tocar "Entendido" llama onDismiss una vez');
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/core/widgets/no_connection_dialog_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar el widget** con los valores de arriba (envolver el test en `MaterialApp` para el tema).

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test test/core/widgets/no_connection_dialog_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add assets/images/icon_no_wifi.png lib/core/widgets/no_connection_dialog.dart test/core/widgets/no_connection_dialog_test.dart
git commit -m "feat(ui): NoConnectionDialog compartido"
```

---

### Task 5: Overlay global y prioridad de estados

**Files:**
- Modify: `lib/app.dart` (renombrar `_GlobalStatusOverlay` → `GlobalStatusOverlay`, público para test; añadir el overlay)
- Modify: `test/widget_test.dart` (sobreescribir `connectivityObserverProvider` con un observer falso que emita `available`; sin esto el plugin real lanza `MissingPluginException` en test)
- Test: `test/core/global_status_overlay_test.dart`

**Interfaces:**
- Consumes: `noConnectionDialogProvider`, `connectivityStatusProvider` (Tasks 2-3), `NoConnectionDialog` (Task 4), `appStatusProvider` (existente).
- Produces: `class GlobalStatusOverlay extends ConsumerWidget { const GlobalStatusOverlay({required Widget child, super.key}); }`

Comportamiento: si `appStatus.isBlocking` → `_BlockingStatusScreen` (sin cambios). Si no, `Stack(child, y si noConnectionDialogProvider: ModalBarrier(dismissible: false) + Center(NoConnectionDialog(isConnectionRestored: status == available, onDismiss: notifier.dismiss)))`. El `builder` de `MaterialApp` queda **por encima** del `Navigator`: no usar `showDialog`; envolver con `Directionality` y `Material(type: MaterialType.transparency)` igual que `_BlockingStatusScreen`. El `child` debe permanecer montado bajo el diálogo.

- [ ] **Step 1: Escribir los tests que fallan**

```dart
testWidgets('diálogo visible: se ve el texto y el contenido de abajo sigue montado');   // find.text('No estás conectado a internet') && find.byKey(contentKey)
testWidgets('diálogo oculto: no aparece');
testWidgets('estado bloqueante activo: no se muestra el diálogo aunque el notifier sea true');
testWidgets('tocar la barrera no descarta el diálogo');
```

Sobrescribir `noConnectionDialogProvider` con un `NoConnectionNotifier` de prueba cuyo `build()` devuelva el valor deseado, y `appStatusProvider` con `AppStatusNotifier` precargado.

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/core/global_status_overlay_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar el overlay en `app.dart` y ajustar `test/widget_test.dart`.**

- [ ] **Step 4: Suite completa**

Run: `flutter test`
Expected: todos los tests pasan (los 34 existentes + los nuevos).

- [ ] **Step 5: Commit**

```bash
git add lib/app.dart test/widget_test.dart test/core/global_status_overlay_test.dart
git commit -m "feat(app): overlay global de sin conexión sobre el árbol de navegación"
```

---

### Task 6: Splash consulta la conectividad antes de navegar

**Files:**
- Modify: `lib/features/onboarding/presentation/splash_screen.dart` (`_proceed`, líneas ~25-36)
- Test: `test/features/onboarding/splash_connectivity_test.dart`

**Interfaces:**
- Consumes: `connectivityObserverProvider.current()`, `noConnectionDialogProvider` (`show()`).

Comportamiento (de `SplashScreen.kt:46-110`): a los 3600 ms, si `current()` es `unavailable` → `noConnectionDialogProvider.notifier.show()` **sin debounce** y no navegar; cuando el diálogo se cierre (estado → `false`, ya sea porque volvió la red o por "Entendido") volver a evaluar `_proceed()`. Con conexión, navegar como hoy. **Desviación documentada:** el Kotlin espera a que el usuario pulse "Entendido"; aquí el diálogo se cierra solo al volver la red (regla de Task 3) y el Splash continúa.

- [ ] **Step 1: Escribir el test que falla**

```dart
testWidgets('sin red a los 3600 ms: no navega y el diálogo queda visible');
testWidgets('al volver la red: el diálogo se cierra y navega a la pantalla inicial');
testWidgets('con red: navega a los 3600 ms como antes');
```

Usar un `GoRouter` mínimo (`/` splash y las rutas de destino como `Placeholder`), `tester.pump(const Duration(milliseconds: 3600))` y un observer falso con `StreamController`.

- [ ] **Step 2: Ejecutar y ver que falla**

Run: `flutter test test/features/onboarding/splash_connectivity_test.dart`
Expected: FAIL (navega siempre).

- [ ] **Step 3: Implementar** el chequeo en `_proceed` y un `ref.listenManual(noConnectionDialogProvider, ...)` en `initState` que reintente `_proceed` cuando pase a `false` y el widget siga montado.

- [ ] **Step 4: Ejecutar y ver que pasa**

Run: `flutter test test/features/onboarding/splash_connectivity_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/features/onboarding/presentation/splash_screen.dart test/features/onboarding/splash_connectivity_test.dart
git commit -m "feat(splash): esperar conexión antes de navegar"
```

---

### Task 7: Verificación final, QA manual y roadmap

**Files:**
- Modify: `docs/MIGRACION_FLUTTER_ROADMAP.md` (línea `NoConnectionDialog`: pasar a `[x]` y retirar la nota de que `connectivity_plus` falta)

- [ ] **Step 1:** `flutter analyze` → `No issues found!`.
- [ ] **Step 2:** `flutter test` → todos en verde.
- [ ] **Step 3:** `flutter build apk --release --flavor municipios -t lib/main_municipios.dart` → `Built ...app-municipios-release.apk`.
- [ ] **Step 4: QA manual en un dispositivo** (APK de Step 3 o `flutter run --flavor municipios`):
  1. Con la app abierta en Home, activar modo avión: a los ~3 s aparece el diálogo; "Entendido" deshabilitado.
  2. Desactivar modo avión: el diálogo se cierra solo.
  3. Activar/desactivar modo avión en menos de 3 s: el diálogo no aparece.
  4. Cerrar la app, activar modo avión y abrirla: en el Splash aparece el diálogo de inmediato (3,6 s) y no avanza; al volver la red continúa.
  5. Forzar un estado bloqueante (Remote Config `app_status_config` en `maintenance` no dismissible) con modo avión: se ve la pantalla roja, no el diálogo.
- [ ] **Step 5: Commit y PR** contra `develop`

```bash
git add docs/MIGRACION_FLUTTER_ROADMAP.md
git commit -m "docs(roadmap): NoConnectionDialog completado"
```
