# Producto 2 — Alcance y mapa de trabajo

> **Contexto (2026-08-13).** Entra un cambio de patrocinador. En esencia es la misma app, alimentada
> por el mismo backend, pero con identidad visual nueva y funcionalidades nuevas. El giro de producto
> es el punto importante: deja de ser una app centrada en el pago de impuestos y pasa a ser una app
> **de ciudadano** — cultural, educativa— con el objetivo explícito de **atraer uso constante**.
>
> Se parte de la base migrada a Flutter. Este documento mapea qué se reutiliza, qué hay que tocar de
> verdad, y propone funcionalidades. El arranque es la semana del **17 de agosto de 2026**.

---

## 1. La premisa estratégica, en una frase

**El pago de impuestos es estructuralmente de baja frecuencia** — se hace una o dos veces al año. Ninguna
mejora de UI arregla eso. Si el objetivo es uso constante, el producto tiene que apoyarse en lo que la
gente hace *muchas veces*: enterarse de qué pasa en su ciudad, apuntarse a cosas, reservar, aprender,
reportar. La buena noticia es que **la base migrada ya tiene sembrado ese terreno** (Cursos y Escenarios
deportivos), solo que hoy están enterrados bajo una jerarquía tributaria.

Dicho de otro modo: el trabajo no es sobre todo *construir módulos nuevos*, es **reordenar la jerarquía
del producto** y añadir el motor de recurrencia. Eso es más barato de lo que parece y es donde está el
retorno.

---

## 2. Qué se reutiliza tal cual

La migración deja una base que absorbe un cambio de patrocinador mucho mejor de lo habitual, porque
**la identidad y el contenido ya vienen del backend en runtime, no del código**.

`GET /api/Municipality/GetInfoBy{id}` devuelve, y la app ya consume:

| Del backend | Qué controla hoy |
|---|---|
| `theme` | Colores completos de la app (`core/theme/`, hex → `ThemeData`) |
| `idShield` | Escudo/logo en cabecera y menú |
| `municipalityProcedures` | **Qué acciones aparecen en la Home** — no hay lista fija en el código |
| `courses` | Módulo Cursos |
| `sportsFacilities` | Módulo Escenarios deportivos |
| `newsByMunicipalities` | Módulo Noticias |
| `queryFields` | Formulario dinámico de consulta de impuestos |
| `municipalitySocialMedia`, `domain`, políticas | Enlaces y textos legales |

**Consecuencia práctica:** cambiar colores, escudo, nombre y el catálogo de acciones de un producto
**no requiere tocar código**. Es configuración de backend más un flavor. Eso ya está probado: el flavor
de Manizales se levantó cambiando un `id` (213).

Infraestructura transversal ya construida y verificada:

- **Red**: 6 base URLs (todas HTTPS, iOS-compatible), 14 servicios Retrofit, 132 DTOs, interceptor
  global de errores, estado global (`operational` / `maintenance` / `force_update` / `server_error`).
- **Sesión**: login nativo + Google, registro en 3 pasos, recuperación de contraseña, perfil.
- **Notificaciones**: FCM push + locales con canales, y **alarmas exactas verificadas bajo Doze**
  (PR #17). Este es el cimiento del motor de recurrencia y ya funciona.
- **Pagos**: PSE, pasarela, historial, factura PDF, escáner de códigos de barras.
- **Recordatorios + calendario**: ya existe, con integración a Google Calendar.
- **Firebase**: Crashlytics, Analytics, Remote Config (4 keys), Messaging.
- **API de clima ya cableada** (`googleWeatherApiUrl`) — hoy infrautilizada, y es contenido de
  consulta diaria natural.

---

## 3. El punto de extensión real (y su límite)

Las acciones de la Home se resuelven en `features/tramites/application/tramite_mappers.dart`, que
despacha por **código numérico de trámite** que envía el backend:

```
case 1..7   → impuestos, PQRD, servicios públicos, PSV…
case 8      → Cursos
case 9      → Escenarios / Reservas
case 10..14 → certificados (residencia, paz y salvo…)
```

**Para añadir una funcionalidad nueva hacen falta tres cosas, y solo una es de app:**

1. Un **código de trámite nuevo** que el backend devuelva en `municipalityProcedures`.
2. Un **`case` nuevo** en el mapper (icono + acción).
3. El **módulo de feature** en `lib/features/<nombre>/` siguiendo `CONVENCIONES.md`.

El límite a tener presente: **ese acoplamiento por código numérico es frágil**. Con 14 casos ya se
sostiene, pero si el producto 2 añade 10 funcionalidades más conviene negociar con backend un
contrato más expresivo (un `type` string + `metadata`) antes de que sean 25 casos numéricos. Es el
momento de plantearlo, porque el backend va a cambiar de todos modos.

---

## 4. Decisión de arquitectura que hay que tomar antes de escribir código

Hay dos caminos y conviene elegir explícitamente, porque condiciona todo lo demás:

**A) Nuevo flavor de la misma app** *(como Manizales)*
Un solo repo, un solo binario por producto, diferenciado por `id` de entidad, tema y flavor.
→ Barato, ya validado. Correcto **si el producto 2 es la misma app con otra piel y algunos módulos más**.

**B) Núcleo compartido + dos apps**
Se extrae `core/` a un package interno y cada producto tiene su propia capa de features y navegación.
→ Más caro al inicio. Correcto **si el producto 2 diverge de verdad**: otra estructura de navegación,
otro modelo mental, funcionalidades que no tienen sentido en Centralización.

**Recomendación:** empezar por **A**, pero con una condición — mover a `core/` toda pieza nueva que sea
genérica desde el primer día, y mantener `features/` sin dependencias cruzadas entre módulos. Así, si
más adelante hace falta B, la extracción es mecánica en vez de una reescritura. La diferencia de coste
entre "hacerlo ordenado desde el principio" y "ordenarlo después" es de semanas.

---

## 5. Propuestas de funcionalidades

Ordenadas por **relación entre impacto en recurrencia y coste**, y anotando qué reutilizan. No son
independientes: los ejes 1 y 4 se refuerzan mutuamente.

### Eje 1 — Agenda cultural y deportiva de la ciudad ⭐ *el de mayor retorno*

La razón por la que alguien abriría la app **cada semana**.

- **Cartelera de eventos**: conciertos, ferias, teatro, mercados, actividades deportivas. Vista de
  calendario y de lista, con filtros por interés.
- **"Me interesa" + recordatorio automático**: un toque y el evento entra en Recordatorios, con
  notificación la víspera. → *Reutiliza el módulo de Recordatorios y las alarmas exactas ya verificadas.*
- **Inscripción a eventos con aforo**: → *Reutiliza casi entero el flujo de inscripción de Cursos
  (validación, confirmación por correo, notificación local).*
- **Añadir a Google Calendar**: → *Ya implementado en Recordatorios.*

**Coste:** medio. La mayor parte es backend (catálogo de eventos); la app reaprovecha tres módulos.
**Impacto en recurrencia:** alto y sostenido.

### Eje 2 — Recompensas ciudadanas ⭐ *el motor de recurrencia*

Es lo que convierte visitas sueltas en hábito, y lo que un patrocinador puede capitalizar.

- **Puntos por participación**: pagar a tiempo, asistir a un curso, reservar un escenario, reportar
  una incidencia, completar el perfil.
- **Beneficios canjeables**: descuentos en escenarios deportivos, entradas a eventos municipales,
  prioridad en cupos de cursos.
- **Racha / progreso visible** en la Home.

**Coste:** medio-alto (requiere modelo de puntos en backend y reglas antifraude).
**Impacto:** es el multiplicador de todo lo demás. Sin esto, cada eje rinde por separado.

⚠️ **Advertencia honesta:** la gamificación municipal fracasa cuando los premios son simbólicos. Si los
beneficios no tienen valor real y disponible, es peor no hacerlo — genera desconfianza. Esto exige
compromiso del patrocinador, no solo desarrollo.

### Eje 3 — Formación y cultura ciudadana

Aprovecha que Cursos ya existe y hoy está infrautilizado.

- **Rutas de aprendizaje**: agrupar cursos en itinerarios con progreso.
- **Certificado de finalización**: → *Reutiliza el módulo de Certificados, que ya genera y comparte PDF.*
- **Cápsulas de contenido**: piezas breves (derechos, trámites, reciclaje, seguridad vial) consumibles
  en dos minutos. Buen encaje con notificaciones segmentadas.

**Coste:** bajo-medio. Es sobre todo contenido y reordenación de lo existente.

### Eje 4 — Participación y reporte ciudadano

- **Reportes georreferenciados**: baches, alumbrado, basuras, con foto y ubicación. → *Reutiliza la
  infraestructura de PQRD (que ya soporta adjuntos), la cámara ya integrada y la ubicación que ya se pide.*
- **Seguimiento del reporte**: estado y notificación al resolverse. Cierra el círculo — es lo que hace
  que la gente vuelva a reportar.
- **Encuestas y consultas ciudadanas**: presupuesto participativo, priorización de obras.

**Coste:** medio. El reporte georreferenciado es el de mejor relación coste/percepción de utilidad.

### Eje 5 — Información útil de consulta diaria

Lo que justifica abrir la app sin tener un trámite pendiente.

- **Panel de ciudad**: clima (**ya cableado, sin usar**), calidad del aire, estado de vías, pico y placa,
  horarios de servicios.
- **Directorio de servicios**: teléfonos útiles, sedes, horarios de atención.

**Coste:** bajo. Alto valor por unidad de esfuerzo, sobre todo pico y placa y clima.

### Eje 6 — Identidad ciudadana

- **Perfil/carné ciudadano** con historial unificado de interacciones (pagos, cursos, reservas, reportes).
- Da sentido narrativo al resto y es el soporte natural de los puntos del Eje 2.

**Coste:** bajo-medio (buena parte del historial ya existe, disperso).

---

## 6. Qué hay que arreglar antes, sí o sí

Reutilizar la base solo sale a cuenta si la base está sana. De la auditoría del 13/08 quedan pendientes
cosas que **encarecen cada feature nueva** — conviene cerrarlas en la primera semana, no después:

1. **Unificar `TopbarNavigation` y `StepIndicator`.** Hoy 18 pantallas declaran su propio `AppBar` y
   hay 2 copias del indicador de pasos. Cada módulo nuevo multiplica esa deuda. **Hacerlo antes de
   añadir features y antes de abrir iOS**, o habrá que revalidar en dos plataformas.
2. **`connectivity_plus` + `NoConnectionDialog`.** Una app de consulta diaria se usa en la calle, con
   mala cobertura. Hoy no hay manejo de desconexión.
3. **Cobertura de tests.** 5 archivos para 31.000 líneas. Si va a crecer y con dos productos encima,
   los mappers y las validaciones necesitan red de seguridad.
4. **CI (GitHub Actions).** Con dos productos × dos tiendas, compilar a mano deja de ser viable.

---

## 7. Riesgos y decisiones abiertas

| Riesgo | Por qué importa | Qué hacer |
|---|---|---|
| **El backend va a cambiar** | La app depende del grafo de `MunicipalityDTO` y de los códigos numéricos de trámite. Un cambio ahí rompe la Home entera. | **Pedir la colección de Postman / spec del nuevo API antes de escribir código.** Es una regla ya establecida en `CLAUDE.md` por incidentes pasados. |
| Códigos numéricos de trámite | 14 casos hoy; con el producto 2 podrían ser 25. Frágil e ilegible. | Negociar con backend un `type` string + `metadata` **ahora**, aprovechando que el contrato cambia igualmente. |
| iOS sin empezar | El producto 2 nace con expectativa de dos plataformas. La cuenta de Apple tarda hasta 2 semanas. | **Iniciar la cuenta de Apple Developer ya**; es una fila, no trabajo. |
| Recompensas sin respaldo real | Gamificación con premios vacíos daña la confianza. | Confirmar compromiso del patrocinador antes de construir el Eje 2. |
| Alcance abierto | "Cultural, educativo, ciudadano" cabe casi todo. | Elegir **2 ejes** para la primera entrega, no seis. |

---

## 8. Recomendación de arranque

Si hubiera que elegir para la primera entrega, con el criterio de máxima recurrencia por esfuerzo:

**Eje 1 (Agenda cultural) + Eje 5 (Panel de ciudad)**, y dejar el Eje 2 (Recompensas) preparado en
modelo de datos pero sin lanzar hasta tener beneficios reales confirmados.

Motivo: el Eje 1 reutiliza tres módulos ya migrados y da la razón para volver cada semana; el Eje 5 es
barato y da la razón para abrir la app cualquier día. Juntos cambian la percepción del producto sin
depender de que el patrocinador cierre acuerdos de beneficios.

---

## 9. Documentos relacionados

- [`MIGRACION_FLUTTER_ROADMAP.md`](MIGRACION_FLUTTER_ROADMAP.md) — estado del cierre de Centralización
- [`MIGRACION_FLUTTER_CONVENCIONES.md`](MIGRACION_FLUTTER_CONVENCIONES.md) — arquitectura por features
- [`MIGRACION_FLUTTER_FLAVORS.md`](MIGRACION_FLUTTER_FLAVORS.md) — playbook de flavors
- [`MIGRACION_FLUTTER_BACKEND.md`](MIGRACION_FLUTTER_BACKEND.md) — contratos actuales (a revisar con el nuevo API)
