# Faltantes de la migración Kotlin → Flutter — índice de planes

> Origen: comparación del Kotlin original (`codebase/`) contra `lib/` el 2026-10-02. Todo lo demás (21/21 paquetes
> de pantallas, 61/66 endpoints) está migrado; el estado completo vive en `docs/MIGRACION_FLUTTER_ROADMAP.md`.

Son **4 comportamientos de la app Android que no son pantallas** y que Flutter aún no tiene. Cada uno es un plan
independiente con su propio PR contra `develop`:

| Orden | Plan | Paquete nuevo | Tamaño | Se puede verificar en local |
|---|---|---|---|---|
| 1 | [Conectividad y `NoConnectionDialog`](2026-10-02-01-conectividad-no-connection-dialog.md) | `connectivity_plus` | M (7 tareas) | Sí (modo avión) |
| 2 | [Notificaciones de confirmación (`NotificationHelper`)](2026-10-02-02-notificaciones-confirmacion.md) | ninguno | S (4 tareas) | Sí |
| 3 | [In-App Review](2026-10-02-03-in-app-review.md) | `in_app_review` | S (4 tareas) | Lógica sí; el diálogo real solo desde Play |
| 4 | [In-App Update (Play Core)](2026-10-02-04-in-app-update.md) | `in_app_update` | S (4 tareas) | Lógica sí; el flujo real solo desde Play |

## Por qué este orden
- **1 primero:** es el único con impacto directo en uso diario (app sin red) y estaba como deuda explícita en el
  roadmap. Los demás son pulido.
- **2** no añade dependencias y reaprovecha `LocalReminderScheduler`: es el más barato.
- **3 y 4 al final:** su verificación real exige una build instalada desde Google Play (pista interna). El 4 además
  depende de que exista la publicación (AAB, `version:` > `versionCode 48`, cuenta de servicio de Play): ver
  "Dependencias externas".

## Reglas de ejecución (valen para los 4 planes)
- **Un PR por plan**, rama desde `develop` (`feature/<nombre>`), PR contra `develop` (confirmar la rama destino
  antes de abrirlo). `main` solo se toca con el PR `develop` → `main`, que dispara el APK firmado.
- **Fusionar en orden y secuencial.** Los planes 1, 3 y 4 modifican `pubspec.yaml` y `pubspec.lock`: tras fusionar uno,
  hacer rebase del siguiente y resolver el lockfile con `flutter pub get`.
- **Antes de abrir cada PR, build release local:**
  `flutter build apk --release --flavor municipios -t lib/main_municipios.dart` (~16 min en esta máquina).
  El CI del PR solo corre `analyze` + `test`; R8 solo actúa en release y el CI de release solo corre al fusionar a
  `main`. Un paquete con reglas de R8 rotas pasaría el PR y fallaría después.
- Cada PR deja `flutter analyze` en 0 issues y `flutter test` en verde (el CI exige `Analyze & test`).
- Actualizar la casilla correspondiente en `docs/MIGRACION_FLUTTER_ROADMAP.md` dentro del mismo PR.

## Desviaciones conscientes respecto al Kotlin (decididas en estos planes)
| Plan | Kotlin | Flutter | Motivo |
|---|---|---|---|
| 1 | 4 estados (`Available/Unavailable/Losing/Lost`) | 2 (`available/unavailable`) | `connectivity_plus` no distingue `Losing/Lost` y el original solo reacciona a "Available vs. el resto" |
| 1 | El diálogo **reemplaza** el contenido | Se **superpone** (`Stack`) | Reemplazar destruiría el árbol de navegación de `go_router` y el estado de formularios |
| 1 | En el Splash el diálogo espera "Entendido" | Se cierra solo al volver la red y el Splash continúa | Mismo notifier global para toda la app; mejor UX, mismo resultado |
| 2 | IDs de notificación `1` y `2` | `-1` y `-2` | Los recordatorios usan el id del servidor (`created.id` y `+1000000`, siempre positivos); `1` y `2` podían pisar un recordatorio real. Un rango alto fijo (`2000001`) también chocaba con `1000001 + 1000000` |
| 2 | Ícono `R.drawable.logo` | `ic_stat_reminder` (ya existente) | Es el ícono que ya usan todas las notificaciones locales de Flutter |
| 3 | Reseña solo tras el 2.º login, una vez para siempre | 2.º login **y** momentos de éxito (PQRD, consulta de impuesto, curso/escenario, pago aprobado); un flujo por sesión | Decisión de producto 2026-10-05 (FSM-59): Google no informa si el diálogo se mostró, y "una vez para siempre" podía gastar la única oportunidad |

## Faltante detectado después (pendiente de plan propio)
- **Eventos de analítica de Firebase del Kotlin:** `MainViewModel.kt`, `LoginOptionsScreen.kt` y `AuthScreen.kt` registran
  `clic_*` (`clic_consulta_impuesto`, `clic_pqrds`, `clic_cursos`, `clic_venues`, `clic_psv`, `clic_historial`, …),
  `login`, `sign_up`, `ContinueWithGoogle` y `ContinueAsGuest`. En Flutter `AnalyticsService` existe pero solo se usa
  para `fcm_subscribed`. Detectado el 2026-10-05 al planear los disparadores de la reseña; se hará en un plan aparte.

## Fuera de alcance (revisado y descartado)
- `WebViewScreen`: el Kotlin lo define pero nunca lo usa.
- Clima: deshabilitado también en el Kotlin (`weatherState` comentado).
- Shimmer: en Flutter existe `main_screen_skeleton.dart` como equivalente.
- iOS (`Info.plist`, `GoogleService-Info.plist`, APNs), flavor `manizales` y publicación en Play Store: son
  trabajos aparte (ver roadmap, Fases 5-7).

## Dependencias externas (no son código)
- **Plan 3 y 4:** probar el flujo real requiere instalar la app desde la **pista de pruebas internas** de Google
  Play. Un APK instalado a mano no muestra el diálogo de reseña ni el de actualización.
- **Plan 4:** además necesita dos versiones subidas a Play con `versionCode` creciente. El `pubspec.yaml` sigue en
  `1.0.0+1` frente a `versionCode 48` de la ficha actual: hay que subirlo antes de la primera publicación.
