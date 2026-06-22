# Migración Trami App — Kotlin → Flutter · Índice

> Punto de entrada de la documentación de migración. Pensado para **leerse en orden** por personas y por agentes de IA que asistan el proceso.

---

## Qué estamos haciendo

Migrar **Trami App Municipios** (hoy Android nativo: Kotlin + Jetpack Compose) a un **proyecto Flutter nuevo desde cero**, multiplataforma (iOS + Android). La app Android actual se mantiene en producción en paralelo durante toda la migración.

A largo plazo, del mismo repositorio Flutter saldrán **apps individuales por municipio** (white-label vía *flavors*), siendo **Trami App Manizales** el primer cliente. El backend se consume **sin cambios**.

---

## Decisiones y forma de trabajo (acordadas)

| Tema | Decisión |
|---|---|
| Estrategia | Proyecto Flutter nuevo desde cero; Android actual sigue vivo en paralelo |
| Estructura/setup del proyecto Flutter | Lo hace **Claude Code** |
| Package / applicationId (por ahora) | **`com.tramites1cero1.centralizacion`** (el mismo de Centralización) |
| Orden | **1º** migrar Centralización completa · **2º** crear Trami App Manizales como flavor |
| Backend | Se consume tal cual, sin cambios |
| Login | Nativo (correo/clave) contra la API propia + Google con Firebase Auth |
| Colores / escudo / módulos | Los define el **backend** (`GET /api/Municipality/GetInfoBy{id}`), no el flavor |

---

## Cómo arrancar

El punto de partida operativo es **[CLAUDE.md](CLAUDE.md)** — el centro de mando que enruta cada tarea, fija las reglas de oro y dice qué documento leer según lo que vayas a hacer. Se carga al inicio de cada sesión de Claude Code.

Para el plan de ejecución concreto (qué hacer y en qué orden, con casillas), usa **[MIGRACION_FLUTTER_ROADMAP.md](MIGRACION_FLUTTER_ROADMAP.md)**.

## Documentos de contexto

1. **[MIGRACION_FLUTTER_BACKEND.md](MIGRACION_FLUTTER_BACKEND.md)** — Todo lo que la app **consume**: las 6 base URLs (microservicios), el inventario completo de endpoints, los contratos de datos (DTOs), los dos caminos de autenticación, el uso real de Firebase y la mecánica white-label a nivel de datos. *Define el contrato con el que el resto trabaja.*

2. **[MIGRACION_FLUTTER_FRONTEND.md](MIGRACION_FLUTTER_FRONTEND.md)** — Cómo la app **se comporta** con lo que recibe: arranque, navegación, theming dinámico, catálogo de módulos/pantallas, el motor de trámites (la lógica más delicada) y consideraciones iOS.

3. **[MIGRACION_FLUTTER_FLAVORS.md](MIGRACION_FLUTTER_FLAVORS.md)** — Cómo sacar **apps individuales por municipio** desde un solo repositorio: qué es un flavor, el `FlavorConfig`, setup de Android/iOS, Firebase por flavor, el playbook para agregar un municipio y los errores comunes a evitar.

4. **[MIGRACION_FLUTTER_CONVENCIONES.md](MIGRACION_FLUTTER_CONVENCIONES.md)** — Arquitectura y reglas de código del proyecto Flutter (estructura de carpetas, Riverpod, Dio, go_router, theming, cómo estructurar un feature). *Garantiza que todo lo migrado se vea igual.*

> Para alimentar un agente: dale el `BACKEND.md` cuando trabaje capa de datos/API, el `FRONTEND.md` para UI/navegación/lógica, el `CONVENCIONES.md` siempre que escriba código, y el `FLAVORS.md` solo cuando lleguemos a empaquetar apps individuales.

---

## Tareas automatizables con agente

Tareas mecánicas y repetitivas que conviene delegar a un agente (ver carpeta [`migration-agent/`](migration-agent/)):

- **Traductor de DTOs Kotlin → Dart** ✅ *(primer experimento, ya creado)* — porta las ~50-70 `data class` a clases Dart con `json_serializable`, compilando y auto-corrigiendo en bucle. Ver [`migration-agent/README.md`](migration-agent/README.md).
- *(Futuro)* Auditor de progreso de migración (qué módulos faltan).
- *(Futuro)* Generador de tests para el motor de trámites (`toInfoTramite` / `toDomainModel`).

---

## Estado del proyecto base (referencia)

- App Android: versión `1.4.6` (versionCode 48), `minSdk 24`, `targetSdk 36`.
- Package actual: `com.tramites1cero1.centralizacion`.
- Stack: Kotlin · Jetpack Compose · Hilt · Retrofit · Firebase (Auth/Messaging/Remote Config/Crashlytics/Analytics) · ML Kit (escáner) · DataStore.

---

*Documentos generados a partir del código de la rama `main`. Mantener este índice actualizado a medida que avance la migración.*
