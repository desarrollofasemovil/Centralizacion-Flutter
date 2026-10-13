# Notificaciones de confirmación (Cursos y Escenarios) — Plan de implementación

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Mostrar una notificación local de confirmación cuando el usuario envía una inscripción a un curso o una reserva de escenario, igual que `NotificationHelper.kt`.

**Architecture:** Un servicio `RegistrationNotifications` en `core/notifications/` que arma el contenido (funciones puras, testeables) y lo publica con el `LocalReminderScheduler` existente. `showNow` gana un parámetro opcional `bigText`. Los notifiers de cursos y escenarios lo llaman en su rama de éxito.

**Tech Stack:** `flutter_local_notifications` (ya en `pubspec`), `flutter_riverpod` 3. **Sin dependencias nuevas.**

**Spec (Kotlin en `codebase/app/src/main/java/com/tramites1cero1/centralizacion/`):** `ui/components/NotificationHelper.kt` (completo), llamadas en `ui/screen/courses/CoursesViewModel.kt:284` y `ui/screen/venues/VenuesViewModel.kt:288`. Roadmap: línea `NotificationHelper` de "Componentes compartidos".

## Global Constraints

- Rama desde `develop` (`feature/notificaciones-confirmacion`); PR contra `develop` (confirmar antes de abrirlo).
- `flutter analyze` en 0 issues, `flutter test` en verde; build release local antes del PR: `flutter build apk --release --flavor municipios -t lib/main_municipios.dart`.
- Canal `reminders_channel` (ya creado por `LocalReminderScheduler`); prioridad alta; `autoCancel` (comportamiento por defecto del plugin).
- **IDs de notificación:** `kCourseNotificationId = 2000001` y `kVenueNotificationId = 2000002`. El Kotlin usaba `1` y `2`, pero aquí los recordatorios usan el id del servidor (`created.id`, y `+1000000` para la confirmación): `1` y `2` podían pisar un recordatorio real.
- Textos **exactos** (copiados del Kotlin; ver Task 1). Mantener el ícono `ic_stat_reminder` que ya usa `LocalReminderScheduler`.
- Una notificación que falla **nunca** debe romper ni retrasar el envío de la inscripción/reserva.

## Review Focus

1. **Permiso de notificaciones denegado:** el envío termina bien y no se lanza excepción (el Kotlin simplemente no notifica). → Task 2.
2. **Reserva con error** (rama `catch`, diálogo de "Aviso de Validación"): no debe notificar; solo la rama de éxito. → Task 3.
3. **Web** (`kIsWeb`; la app ya tiene build web de desarrollo): `flutter_local_notifications` no la soporta; debe devolver `false` sin crashear. → Task 2.
4. **Nombres/títulos con comillas, tildes o muy largos:** el texto se arma tal cual, sin cortar ni lanzar. → Task 1.
5. **Dos envíos seguidos:** el segundo reemplaza al primero (mismo id, como en el Kotlin); está aceptado y documentado, no se arregla aquí. → Task 3 (solo aserción de id).

---

### Task 1: Contenido de las notificaciones

**Files:**
- Create: `lib/core/notifications/registration_notifications.dart` (solo contenido e ids en esta tarea)
- Test: `test/core/notifications/registration_notifications_test.dart`

**Interfaces:**
- Produces:
  - `const int kCourseNotificationId = 2000001; const int kVenueNotificationId = 2000002;`
  - `class NotificationContent { const NotificationContent({required String title, required String body, required String bigText}); }`
  - `NotificationContent courseRegistrationContent({required String courseTitle, required String userName})`
  - `NotificationContent venueReservationContent({required String venueTitle, required String userName, required String date, required String time})`

Textos fijados por el Kotlin:
- Curso — título: `¡Solicitud Enviada!`; cuerpo: `$userName, hemos recibido tu solicitud para el curso '$courseTitle'. Un funcionario la revisará y te contactará pronto.`; texto largo: `$userName, tu solicitud de inscripción al curso '$courseTitle' ha sido enviada exitosamente. Un funcionario validará la información y se pondrá en contacto contigo.`
- Escenario — título: `¡Solicitud de Reserva Enviada!`; cuerpo: `$userName, tu solicitud para '$venueTitle' ha sido enviada a revisión.`; texto largo: `$userName, la solicitud de reserva en '$venueTitle' para el $date a las $time ha sido enviada correctamente. Un funcionario validará la disponibilidad y se pondrá en contacto contigo pronto.`

- [ ] **Step 1: Escribir los tests que fallan**

```dart
test('curso: título, cuerpo y texto largo exactos', () {
  final c = courseRegistrationContent(courseTitle: 'Yoga', userName: 'Ana');
  expect(c.title, '¡Solicitud Enviada!');
  expect(c.body, "Ana, hemos recibido tu solicitud para el curso 'Yoga'. Un funcionario la revisará y te contactará pronto.");
  expect(c.bigText, "Ana, tu solicitud de inscripción al curso 'Yoga' ha sido enviada exitosamente. Un funcionario validará la información y se pondrá en contacto contigo.");
});
test('escenario: título, cuerpo y texto largo exactos', () { /* venue 'Cancha 1', Ana, '2026-10-10', '15:00' */ });
test("comillas, tildes y títulos largos pasan intactos", () { /* "Niño's  Fútbol" y 300 caracteres */ });
test('ids distintos entre sí y fuera del rango de recordatorios del servidor', () {
  expect(kCourseNotificationId, isNot(kVenueNotificationId));
});
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/core/notifications/registration_notifications_test.dart`
Expected: FAIL (símbolos no definidos).

- [ ] **Step 3: Implementar** las dos funciones puras y las constantes en `registration_notifications.dart`.

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test test/core/notifications/registration_notifications_test.dart`
Expected: PASS (4 tests).

- [ ] **Step 5: Commit**

```bash
git add lib/core/notifications/registration_notifications.dart test/core/notifications/registration_notifications_test.dart
git commit -m "feat(notifications): contenido de confirmación de cursos y escenarios"
```

---

### Task 2: `showNow` con texto largo y servicio de publicación

**Files:**
- Modify: `lib/core/notifications/local_reminder_scheduler.dart` (`showNow`, ~línea 183)
- Modify: `lib/core/notifications/registration_notifications.dart`
- Test: `test/core/notifications/registration_notifications_test.dart` (ampliar)

**Interfaces:**
- Consumes: `LocalReminderScheduler.showNow` (cambia de firma, ver abajo), `NotificationContent` (Task 1).
- Produces:
  - `Future<bool> LocalReminderScheduler.showNow({required int id, required String title, required String body, String? bigText})` — retrocompatible: sin `bigText` se comporta como hoy.
  - `class RegistrationNotifications { RegistrationNotifications(LocalReminderScheduler scheduler); Future<bool> showCourseRegistration({required String courseTitle, required String userName}); Future<bool> showVenueReservation({required String venueTitle, required String userName, required String date, required String time}); }`
  - `final registrationNotificationsProvider = Provider<RegistrationNotifications>(...)`

Con `bigText` no nulo, `showNow` construye `AndroidNotificationDetails` con `styleInformation: BigTextStyleInformation(bigText)` (mismo canal, ícono e importancia que `_details`); los demás llamadores (`reminders_notifier.dart:253`) no cambian.

- [ ] **Step 1: Escribir los tests que fallan**

Un `_FakeScheduler extends LocalReminderScheduler` (constructor `super(FlutterLocalNotificationsPlugin())`) que sobreescribe `showNow` para guardar `(id, title, body, bigText)` y devolver un valor configurable.

```dart
test('showCourseRegistration publica con id, título, cuerpo y bigText del curso', () async { /* verifica kCourseNotificationId y NotificationContent */ });
test('showVenueReservation publica con kVenueNotificationId', () async { /* ... */ });
test('si showNow devuelve false (permiso denegado) el servicio devuelve false y no lanza', () async { /* ... */ });
test('si showNow lanza, el servicio lo captura y devuelve false (p. ej. web)', () async { /* ... */ });
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/core/notifications/registration_notifications_test.dart`
Expected: FAIL.

- [ ] **Step 3: Implementar** la nueva firma de `showNow` y `RegistrationNotifications` (envolver la llamada en `try/catch` → `false`).

- [ ] **Step 4: Ejecutar y ver que pasan** (incluye los tests de recordatorios existentes)

Run: `flutter test test/core`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/core/notifications test/core/notifications
git commit -m "feat(notifications): servicio de confirmaciones y showNow con texto largo"
```

---

### Task 3: Conectar cursos y escenarios

**Files:**
- Modify: `lib/features/cursos/application/courses_notifier.dart` (`submitRegistration`, tras `await _repo.registerForCourse(payload)` ~línea 186)
- Modify: `lib/features/venues/application/venues_notifier.dart` (`submitReservation`, rama de éxito tras `await _repo.createReservation(request)` ~línea 223)
- Test: `test/features/cursos/courses_notifier_notification_test.dart`, `test/features/venues/venues_notifier_notification_test.dart`

**Interfaces:**
- Consumes: `registrationNotificationsProvider` (Task 2); `coursesRepositoryProvider`, `venuesRepositoryProvider` (existentes).

Llamar con `unawaited(ref.read(registrationNotificationsProvider).showCourseRegistration(courseTitle: <título del curso seleccionado>, userName: <primer nombre del formulario>))`. Verificar el nombre del campo del título en `CourseDTO` (`lib/core/models/course_dto.dart`); `VenueDTO.title` existe. Para escenarios usar `request.firstName`, `request.date`, `request.time`. En el escenario, solo en la rama de éxito (no en el `catch`).

- [ ] **Step 1: Escribir los tests que fallan**

Probar con `ProviderContainer` sobreescribiendo: el repositorio (clase falsa que implemente la interfaz concreta), `registrationNotificationsProvider` (falso que cuenta llamadas) y `sharedPreferencesProvider` (con `SharedPreferences.setMockInitialValues({})`, porque el notifier lee `sessionProvider` en `build()`). Construir `CoursesParam`/`VenuesParam` según sus constructores.

```dart
test('inscripción exitosa: notifica una vez con el título del curso y el primer nombre');
test('inscripción fallida: no notifica');
test('reserva exitosa: notifica con título, nombre, fecha y hora');
test('reserva con error (catch): no notifica');
test('si la notificación falla, la inscripción igual queda en registrationSuccess == true');
```

- [ ] **Step 2: Ejecutar y ver que fallan**

Run: `flutter test test/features/cursos test/features/venues`
Expected: FAIL.

- [ ] **Step 3: Implementar** las dos llamadas.

- [ ] **Step 4: Ejecutar y ver que pasan**

Run: `flutter test`
Expected: toda la suite en verde.

- [ ] **Step 5: Commit**

```bash
git add lib/features/cursos lib/features/venues test/features
git commit -m "feat(cursos,venues): notificación local al enviar inscripción o reserva"
```

---

### Task 4: Verificación final, QA manual y roadmap

**Files:**
- Modify: `docs/MIGRACION_FLUTTER_ROADMAP.md` (línea `NotificationHelper` → `[x]`)

- [ ] **Step 1:** `flutter analyze` → `No issues found!`.
- [ ] **Step 2:** `flutter test` → todos en verde.
- [ ] **Step 3:** `flutter build apk --release --flavor municipios -t lib/main_municipios.dart` → `Built ...app-municipios-release.apk`.
- [ ] **Step 4: QA manual en dispositivo** con un municipio que tenga Cursos y Escenarios (p. ej. Amalfi):
  1. Inscribirse a un curso con sesión iniciada: llega "¡Solicitud Enviada!" con el texto largo expandible.
  2. Reservar un escenario: llega "¡Solicitud de Reserva Enviada!" con fecha y hora.
  3. Revocar el permiso de notificaciones y repetir: el envío funciona y no hay notificación ni error.
  4. Reservar un horario ocupado (error): no llega notificación.
- [ ] **Step 5: Commit y PR** contra `develop`

```bash
git add docs/MIGRACION_FLUTTER_ROADMAP.md
git commit -m "docs(roadmap): NotificationHelper completado"
```
