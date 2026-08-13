# CLAUDE.md — Centro de mando de la migración a Flutter

> Este archivo dirige el trabajo de migración de **Trami App Municipios** (Kotlin/Compose) a **Flutter**. Está pensado para cargarse al inicio de cada sesión de Claude Code y enrutar a la documentación y tareas correctas.
> Lee los archivos `MIGRACION_FLUTTER_*` en `docs/` (junto a este archivo).
>
> ⭐ **IMPORTANTE — Fuente de verdad = el código Kotlin original.** El proyecto Android completo (Kotlin + Jetpack Compose) está espejado en **`tramiapp_flutter/codebase/`**. El código de las pantallas y la lógica vive en `tramiapp_flutter/codebase/app/src/main/java/com/tramites1cero1/centralizacion/` (pantallas en `.../ui/screen/<feature>/`). **Antes de migrar o rediseñar CUALQUIER módulo, abre y lee su código real en `codebase/`.** Los `.md` describen el comportamiento, pero el código de `codebase/` manda: porta fielmente diseño y lógica, no reinterpretes.
>
> ⚠️ **`codebase/` está en `.gitignore` (espejo local, NO se versiona).** Si no la tienes en tu copia local, clónala desde el repo Android original antes de trabajar:
> ```bash
> git clone https://github.com/desarrollofasemovil/Centralizacion.git tramiapp_flutter/codebase
> ```
> Sin esta carpeta, cualquier migración de UI se basará solo en los `.md` y divergirá del diseño real (ya pasó en la Fase 2).

---

## Reglas de oro (no negociables)

1. **El backend se consume sin cambios.** Las 6 base URLs y todos los endpoints están en `MIGRACION_FLUTTER_BACKEND.md`. No inventes endpoints ni cambies contratos.
   > ⚠️ **Cambio en curso (desde 2026-08-13):** por el cambio de patrocinador va a haber cambios en el API. Hasta que lleguen la spec/colección de Postman nuevas, `BACKEND.md` sigue siendo la verdad. **No asumas el contrato nuevo: pídelo.** Ver [`docs/PRODUCTO_2_ALCANCE.md`](docs/PRODUCTO_2_ALCANCE.md) §7.
2. **Colores, escudo y módulos los define el backend** (`GET /api/Municipality/GetInfoBy{id}`), nunca el código ni el flavor. Se aplican en runtime.
3. **Dos caminos de autenticación:** login nativo (correo/clave) contra la API propia (NO usa Firebase Auth) + login con Google (único uso de Firebase Auth). Ver `BACKEND.md §5`.
4. **Package / applicationId por ahora:** `com.tramites1cero1.centralizacion` (el mismo de Centralización).
5. **Orden de trabajo:** la migración de **Centralización está funcionalmente completa en Android** (los 21 paquetes de pantallas Kotlin tienen equivalente en Flutter). El foco actual es **pulir detalles visuales, cerrar deuda de componentes compartidos y abrir iOS**. **Manizales** va por la mitad, en la rama `claude/manizales-shield-flavor-apk-41c6c7`, aún sin mezclar. Estado medido y verificado en `MIGRACION_FLUTTER_ROADMAP.md`.
6. **iOS = HTTPS siempre.** No portar `usesCleartextTraffic`; iOS bloquea HTTP. Confirmar que todos los endpoints son HTTPS.
7. **Sigue las convenciones** de `MIGRACION_FLUTTER_CONVENCIONES.md` para que cada módulo migrado se vea igual. No improvises arquitectura por módulo. **La referencia visual de cada pantalla es su `*Screen.kt` original en `codebase/` — no rediseñes ni reinterpretes la UI.**
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
| **Producto 2** (cambio de patrocinador): alcance, funcionalidades nuevas, decisiones abiertas | [PRODUCTO_2_ALCANCE.md](docs/PRODUCTO_2_ALCANCE.md) |
| Visión general / índice | [MIGRACION_FLUTTER_README.md](MIGRACION_FLUTTER_README.md) |

El código Kotlin original está en `tramiapp_flutter/codebase/app/src/main/java/com/tramites1cero1/centralizacion/` (pantallas en `.../ui/screen/<feature>/`). Úsalo como **fuente de verdad** del comportamiento **y del diseño** actual; ábrelo siempre antes de portar un módulo. Si la carpeta no existe localmente, clónala (ver nota al inicio de este archivo).

---

## 🕸️ Grafo de conocimiento del código (graphify)

El código Flutter está mapeado en un **grafo de conocimiento** (generado con [graphify](https://github.com/Graphify-Labs/graphify)): clases, widgets, providers, servicios API y DTOs con sus relaciones e imports, más los títulos de los `.md` de `docs/`. Vive en `graphify-out/` (ignorado por git, se regenera). **Al inicio de cualquier tarea de arquitectura o de "¿dónde está X? / ¿qué depende de Y?", consúltalo antes de hacer grep a ciegas.** No sustituye la Regla de oro: para el diseño y comportamiento de una pantalla la fuente de verdad sigue siendo el Kotlin en `codebase/`; el grafo mapea el código Flutter **ya migrado**.

**Consultarlo** (desde la raíz `tramiapp_flutter/`):
```bash
graphify query "cómo funciona la autenticación y la sesión"   # traversal BFS: contexto amplio
graphify path "SessionNotifier" "UserPreferences"             # camino más corto entre dos nodos
graphify explain "sessionProvider"                            # explica un nodo y sus vecinos
```
O lee el resumen curado en [`graphify-out/GRAPH_REPORT.md`](graphify-out/GRAPH_REPORT.md) (nodos-dios, conexiones sorprendentes, preguntas sugeridas) y abre `graphify-out/graph.html` para la vista interactiva.

**Mantenerlo fresco:** tras cambiar código corre `graphify update .` — solo AST con tree-sitter, **sin LLM, sin API key, nada sale de tu máquina**; es incremental (ignora lo que no cambió). Si `graphify-out/` no existe (clon o worktree nuevo), reconstrúyelo con `/graphify .`.

**Instalación** (una vez por máquina): `pip install graphifyy && graphify install`.

---

## Flujo de trabajo al migrar un módulo

1. **Ubica el módulo** en el catálogo de `FRONTEND.md §5` y en el roadmap.
2. **Lee el comportamiento y el diseño actual** en el código Kotlin original del módulo: abre el `*Screen.kt` y su `*ViewModel` en `codebase/app/src/main/java/com/tramites1cero1/centralizacion/ui/screen/<feature>/`.
3. **Identifica los endpoints** que consume en `BACKEND.md §3` y sus DTOs en `§4`.
4. **Implementa** siguiendo `CONVENCIONES.md` (estructura de feature, Riverpod, Dio, go_router).
5. **Verifica** (`flutter analyze`, y la pantalla corre).
6. **Marca la casilla** correspondiente en el roadmap.

---

## Tareas automatizables (agente)

- **Traductor de DTOs Kotlin → Dart**: ya existe en [`migration-agent/`](migration-agent/). Úsalo para portar las ~50-70 `data class` en lote en vez de a mano. Ver [`migration-agent/README.md`](migration-agent/README.md).

---

## Qué NO hacer

- No migres UI a ciegas desde los `.md`. Si no tienes la carpeta `codebase/`, clónala antes (ver nota al inicio); no rediseñes ni reinterpretes una pantalla sin leer su `*Screen.kt` original.
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

## API Integration
- Never assume API contracts (token format, HTTP method, endpoint paths, response shape). Ask for or read the Postman collection / API spec before implementing auth or network code.

> _Why: Several auth/login sessions broke because Claude assumed GUID tokens, placeholder endpoints, or wrong HTTP methods instead of using the real spec._

## Assumptions
- Do not assume project-specific behavior (flavors, Firebase usage, TextTheme config, device architecture). Confirm with the user or read the relevant docs before building on assumptions.

> _Why: Repeated friction came from Claude assuming flavor/Firebase behavior, skipping TextTheme, and targeting the wrong device architecture._

## Flutter Standards
- Follow the existing AppTheme/design system and ensure `flutter analyze` returns 0 errors before committing.

> _Why: Most feature sessions explicitly required AppTheme compliance and clean analyzer output as a success bar._


## Branch & PR Targeting
- Always confirm the target branch before opening a PR (default to `develop`, NOT `main`).
- When working in a worktree, confirm whether testing/changes should happen on the worktree or the main route, and branch worktrees from `develop` unless told otherwise.

> _Why: Multiple sessions had friction from PRs targeting main, worktrees branching from main, and testing on the wrong route requiring interruptions._
