# CLAUDE.md — Centro de mando de la migración a Flutter

> Este archivo dirige el trabajo de migración de **Trami App Municipios** (Kotlin/Compose) a **Flutter**. Está pensado para cargarse al inicio de cada sesión de Claude Code y enrutar a la documentación y tareas correctas.
>
> **Destino:** cuando se cree el proyecto Flutter (`tramiapp_flutter/`), copiar este `CLAUDE.md` y los `MIGRACION_FLUTTER_*.md` a su raíz. Por ahora viven en el repo de Centralización junto al código fuente original.

---

## Reglas de oro (no negociables)

1. **El backend se consume sin cambios.** Las 6 base URLs y todos los endpoints están en `MIGRACION_FLUTTER_BACKEND.md`. No inventes endpoints ni cambies contratos.
2. **Colores, escudo y módulos los define el backend** (`GET /api/Municipality/GetInfoBy{id}`), nunca el código ni el flavor. Se aplican en runtime.
3. **Dos caminos de autenticación:** login nativo (correo/clave) contra la API propia (NO usa Firebase Auth) + login con Google (único uso de Firebase Auth). Ver `BACKEND.md §5`.
4. **Package / applicationId por ahora:** `com.tramites1cero1.centralizacion` (el mismo de Centralización).
5. **Orden de trabajo:** primero migrar **Centralización completa**, después crear **Trami App Manizales** como flavor. No empezar Manizales antes de tiempo.
6. **iOS = HTTPS siempre.** No portar `usesCleartextTraffic`; iOS bloquea HTTP. Confirmar que todos los endpoints son HTTPS.
7. **Sigue las convenciones** de `MIGRACION_FLUTTER_CONVENCIONES.md` para que cada módulo migrado se vea igual. No improvises arquitectura por módulo.
8. **Actualiza el roadmap.** Al completar una tarea, marca su casilla en `MIGRACION_FLUTTER_ROADMAP.md`.

---

## Mapa de documentos — qué leer según la tarea

| Si vas a trabajar en… | Lee primero |
|---|---|
| Capa de datos, API, DTOs, auth, Firebase | [MIGRACION_FLUTTER_BACKEND.md](MIGRACION_FLUTTER_BACKEND.md) |
| UI, navegación, theming, pantallas, lógica de trámites | [MIGRACION_FLUTTER_FRONTEND.md](MIGRACION_FLUTTER_FRONTEND.md) |
| Apps individuales por municipio (Manizales) | [MIGRACION_FLUTTER_FLAVORS.md](MIGRACION_FLUTTER_FLAVORS.md) |
| Arquitectura, estructura de carpetas, patrones de código | [MIGRACION_FLUTTER_CONVENCIONES.md](MIGRACION_FLUTTER_CONVENCIONES.md) |
| Qué hacer y en qué orden (checklist) | [MIGRACION_FLUTTER_ROADMAP.md](MIGRACION_FLUTTER_ROADMAP.md) |
| Visión general / índice | [MIGRACION_FLUTTER_README.md](MIGRACION_FLUTTER_README.md) |

El código Kotlin original está en `app/src/main/java/com/tramites1cero1/centralizacion/`. Úsalo como fuente de verdad del comportamiento actual.

---

## Flujo de trabajo al migrar un módulo

1. **Ubica el módulo** en el catálogo de `FRONTEND.md §5` y en el roadmap.
2. **Lee el comportamiento actual** en el código Kotlin original del módulo.
3. **Identifica los endpoints** que consume en `BACKEND.md §3` y sus DTOs en `§4`.
4. **Implementa** siguiendo `CONVENCIONES.md` (estructura de feature, Riverpod, Dio, go_router).
5. **Verifica** (`flutter analyze`, y la pantalla corre).
6. **Marca la casilla** correspondiente en el roadmap.

---

## Tareas automatizables (agente)

- **Traductor de DTOs Kotlin → Dart**: ya existe en [`migration-agent/`](migration-agent/). Úsalo para portar las ~50-70 `data class` en lote en vez de a mano. Ver [`migration-agent/README.md`](migration-agent/README.md).

---

## Qué NO hacer

- No metas colores/módulos/escudo en el código o el flavor (vienen del backend).
- No uses Firebase Auth para el login nativo.
- No cambies el `applicationId` del flavor `municipios` (debe conservar la app de Play Store).
- No empieces a configurar Trami App Manizales hasta terminar Centralización.
- No traduzcas datos largos por la ruta de navegación (usa estado/extra) — ver `FRONTEND.md §11`.
- No portes la base URL local HTTP comentada ni `usesCleartextTraffic`.

---

## Comandos útiles (una vez exista el proyecto Flutter)

```bash
# Generar código de json_serializable / freezed
flutter pub run build_runner build --delete-conflicting-outputs

# Correr por flavor
flutter run --flavor municipios -t lib/main_municipios.dart
flutter run --flavor manizales  -t lib/main_manizales.dart

# Análisis estático
flutter analyze
```
