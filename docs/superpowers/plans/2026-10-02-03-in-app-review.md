# In-App Review — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Pedir la reseña de la tienda una sola vez, a partir del segundo inicio de sesión con correo y contraseña, igual que `InAppReviewManager.kt`.

**Architecture:** `ReviewPromptService` en `core/review/` (cuenta inicios de sesión y decide si pedir la reseña) sobre un `ReviewLauncher` abstracto (envuelve `in_app_review`) y las preferencias locales. Se invoca desde el flujo de login nativo, después del diálogo de éxito.

**Tech Stack:** `in_app_review` ^2.0.12 (resolvió 2.0.12 el 2026-10-02), `shared_preferences` (ya en `pubspec`), `flutter_riverpod` 3.

**Spec (Kotlin en `codebase/app/src/main/java/com/tramites1cero1/centralizacion/`):** `utils/InAppReviewManager.kt` (completo), `ui/screen/login/AuthViewModel.kt:128-142` (incremento y evento), consumidores del evento en `ui/screen/main/MainScreen.kt:309-318` y `ui/screen/history/HistoryPayScreen.kt:125-132`.

> **Ampliación del 2026-10-05 (decisión de producto, FSM-59).** Se conserva la regla del login y se añaden
> disparadores en momentos de éxito: PQRD radicada (al aceptar el diálogo del ticket, anónima o identificada),
> volver atrás desde los resultados de la consulta de impuesto (con al menos una factura), cerrar la confirmación de
> inscripción a curso o de reserva de escenario, y pago aprobado (tras "Verificar estado" o al sincronizar en el
> historial). La frecuencia pasa de "una vez para siempre" a **como mucho un flujo completado por sesión de la app**;
> la clave `in_app_review_prompt_shown` ya no se usa. Las Tasks 3b–3e se añadieron en la ejecución; ver el PR.

## Global Constraints

- Rama desde `develop` (`feature/in-app-review`); PR contra `develop` (confirmar antes de abrirlo).
- `flutter analyze` en 0 issues, `flutter test` en verde; build release local antes del PR: `flutter build apk --release --flavor municipios -t lib/main_municipios.dart`.
- **Umbral: 2 inicios de sesión** (`LOGIN_COUNT_THRESHOLD = 2`). Se pide si `count >= 2 && !yaMostrado`.
- Solo cuenta el login **nativo (correo/clave)**. El login con Google **no** cuenta (en el Kotlin tampoco: solo `AuthViewModel.authenticate` incrementa).
- El contador se incrementa en **cada** login exitoso, incluso después de haber mostrado la reseña.
- "Ya mostrado" se marca **solo cuando el flujo terminó** (Kotlin: dentro del `addOnCompleteListener` del `launchReviewFlow`). Si no hay disponibilidad o falla, no se marca y se reintenta en el siguiente login.
- Claves en `shared_preferences`: `in_app_review_login_count` (int) y `in_app_review_prompt_shown` (bool). (Prefijadas porque aquí comparten espacio con el resto de preferencias; el Kotlin usaba un archivo aparte.)

## Review Focus

1. **Sin disponibilidad** (APK instalado a mano, web, escritorio; `isAvailable()` es `false`): no crashea y no marca "mostrado". → Task 2.
2. **El flujo lanza excepción:** no marca "mostrado"; el siguiente login reintenta. → Task 2.
3. **Tercer login y siguientes tras haberse mostrado:** nunca vuelve a pedirse, aunque el contador siga subiendo. → Task 2.
4. **Persistencia entre reinicios:** el contador sobrevive a cerrar la app (`SharedPreferences`). → Task 2.
5. **Login fallido:** no incrementa nada. → Task 3.

---

### Task 1: Dependencia y verificación de compilación

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`

**Interfaces:**
- Produces: `package:in_app_review/in_app_review.dart` (`InAppReview.instance.isAvailable()` → `Future<bool>`, `.requestReview()` → `Future<void>`).

- [ ] **Step 1: Añadir la dependencia**

Run: `flutter pub add in_app_review`
Expected: añade `in_app_review: ^2.0.12` (o la vigente).

- [ ] **Step 2: Compilar el flavor**

Run: `flutter build apk --debug --flavor municipios -t lib/main_municipios.dart`
Expected: `Built build\app\outputs\flutter-apk\app-municipios-debug.apk`. Si falla por el plugin, parar y reportar. El plugin usa Play Core de forma transitiva: confirmar en Task 4 que el build **release** (R8) también pasa.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add in_app_review"
```

---

### Task 2: Servicio de reseña y preferencias

**Files:**
- Modify: `lib/core/storage/user_preferences.dart` (añadir métodos y claves)
- Create: `lib/core/review/review_prompt_service.dart`
- Test: `test/core/review/review_prompt_service_test.dart`

**Interfaces:**
- Consumes: `UserPreferences` (existente), `InAppReview`.
- Produces:
  - En `UserPreferences`: `int reviewLoginCount()`, `Future<void> incrementReviewLoginCount()`, `bool reviewPromptShown()`, `Future<void> markReviewPromptShown()`.
  - `abstract class ReviewLauncher { Future<bool> launch(); }` — devuelve `true` si el flujo se ejecutó hasta el final.
  - `class InAppReviewLauncher implements ReviewLauncher` — `launch()` devuelve `false` si `isAvailable()` es `false`; si no, `await requestReview()` y `true`. Captura cualquier excepción y devuelve `false`.
  - `class ReviewPromptService { ReviewPromptService(UserPreferences prefs, ReviewLauncher launcher); static const int loginThreshold = 2; Future<bool> onSuccessfulLogin(); }` — devuelve `true` si lanzó y completó el flujo.
  - `final reviewPromptServiceProvider = Provider<ReviewPromptService>(...)`

- [ ] **Step 1: Escribir los tests que fallan**

Con `SharedPreferences.setMockInitialValues({})` y un `_FakeLauncher` (cuenta llamadas y devuelve un resultado configurable):

```dart
test('primer login: incrementa a 1 y no lanza la reseña', ...);
test('segundo login: lanza la reseña y la marca como mostrada si el flujo completó', ...);
test('tercer login y siguientes: no vuelve a lanzar; el contador sigue subiendo', ...);
test('launcher devuelve false (sin disponibilidad): no marca mostrada y el siguiente login reintenta', ...);
test('launcher lanza excepción: no marca mostrada y el servicio no propaga el error', ...);
test('el contador persiste: una instancia nueva con las mismas preferencias continúa la cuenta', ...);
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/core/review/review_prompt_service_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar** preferencias, launcher y servicio. Orden en `onSuccessfulLogin`: incrementar → evaluar `count >= loginThreshold && !shown` → lanzar → marcar solo si el launcher devolvió `true`.

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test test/core/review/review_prompt_service_test.dart`
Expected: PASS (6 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/storage/user_preferences.dart lib/core/review test/core/review
git commit -m "feat(review): servicio de In-App Review con umbral de 2 logins"
```

---

### Task 3: Conectar el login nativo

**Files:**
- Modify: `lib/features/auth/presentation/login_bottom_sheet.dart` (`showLoginBottomSheet`, `case _SheetResult.loggedIn`, líneas ~30-46)
- Test: `test/features/auth/login_review_hook_test.dart`

**Interfaces:**
- Consumes: `reviewPromptServiceProvider` (Task 2), `sessionProvider`/`authRepositoryProvider` (existentes).

Tras cerrar el diálogo "Inicio de sesión exitoso", si `context.mounted`, llamar `unawaited(ProviderScope.containerOf(context, listen: false).read(reviewPromptServiceProvider).onSuccessfulLogin())`. No va dentro de `_login()` del sheet: ese widget se destruye al cerrarse y la reseña debe pedirse con la pantalla de destino ya visible (como el Kotlin, que lo consume en `MainScreen`).

- [ ] **Step 1: Escribir los tests que fallan**

Con un `authRepositoryProvider` falso (login exitoso/fallido) y un `reviewPromptServiceProvider` falso que cuenta llamadas:

```dart
testWidgets('login exitoso y diálogo aceptado: llama onSuccessfulLogin una vez');
testWidgets('login fallido: no llama onSuccessfulLogin');
testWidgets('cerrar el sheet sin iniciar sesión: no llama onSuccessfulLogin');
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/features/auth/login_review_hook_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar** la llamada en el `case`.

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test`
Expected: toda la suite en verde.

- [ ] **Step 5: Commit**

```bash
git add lib/features/auth/presentation/login_bottom_sheet.dart test/features/auth
git commit -m "feat(auth): pedir reseña tras el segundo login nativo"
```

---

### Task 4: Verificación final, QA manual y roadmap

**Files:**
- Modify: `docs/MIGRACION_FLUTTER_ROADMAP.md` (añadir una línea `In-App Review` bajo "Componentes compartidos" marcada `[x]`; no existía en el roadmap)

- [ ] **Step 1:** `flutter analyze` → `No issues found!`.
- [ ] **Step 2:** `flutter test` → todos en verde.
- [ ] **Step 3:** `flutter build apk --release --flavor municipios -t lib/main_municipios.dart` → `Built ...app-municipios-release.apk` (valida R8 con Play Core).
- [ ] **Step 4: QA manual.**
  - En **APK instalado a mano:** iniciar sesión dos veces. No debe aparecer nada ni haber errores (`isAvailable()` es `false`); revisar `adb logcat` sin excepciones.
  - En **build instalada desde la pista interna de Play** (requiere publicación, ver índice): el segundo login muestra el diálogo de reseña de Play una sola vez; un tercer login no lo repite. La cuota de Google puede ocultar el diálogo aunque la lógica sea correcta: no es un fallo.
- [ ] **Step 5: Commit y PR** contra `develop`

```bash
git add docs/MIGRACION_FLUTTER_ROADMAP.md
git commit -m "docs(roadmap): In-App Review completado"
```
