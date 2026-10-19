# Analítica — catálogo de eventos (Firebase Analytics / GA4)

> Fuente en código: [`lib/core/analytics/analytics_service.dart`](../lib/core/analytics/analytics_service.dart).
> Ningún evento lleva datos personales (cédula, correo, teléfono, URL completa).

## Fase 0 — paridad con Kotlin + correcciones (2026-10-19)

La migración a Flutter había dejado `AnalyticsService` sin ninguna llamada y nadie se
suscribía al tópico FCM del municipio. Esta fase lo devuelve y corrige lo que en el
original no servía para reportes.

### Propiedades de usuario

| Propiedad | Valor | Para qué |
|---|---|---|
| `municipio` | nombre normalizado (`El_Carmen_de_Viboral`, máx. 36) | segmentar cualquier evento y armar audiencias para Firebase Messaging |
| `municipio_id` | id del backend | cruzar con datos del backend |

> Registrarlas como **dimensiones personalizadas de usuario** en GA4 (Admin → Definiciones
> personalizadas) para verlas en los informes.

### Tópico FCM

`theme_<municipio normalizado>` al entrar a la Home, igual que `MunicipalityViewModel.kt`.
Acumulativo (no se desuscribe del municipio anterior), como el original. Evento `fcm_subscribed`
`{topic}` la primera vez por proceso.

### Eventos

| Evento | Cuándo | Parámetros | Cambio vs Kotlin |
|---|---|---|---|
| `seleccion_municipio` | entra a la Home de un municipio (una vez por proceso) | `municipio_id`, `municipio` | **Reemplaza `event_<municipio>`** (un nombre de evento por municipio) |
| `clic_pqrds` | trámite PQRDS | comunes¹ | params nuevos |
| `clic_url_directa` | trámite que abre URL externa | comunes¹, `url_dominio`, `requiere_datos` (`si`/`no`) | antes mandaba la URL completa |
| `clic_boton_panico` | botón de pánico | comunes¹ | ya no manda la URL de WhatsApp |
| `clic_navegacion_nativa` | trámite con ruta nativa | comunes¹, `ruta` | — |
| `clic_certificado` | certificados | comunes¹ | **nuevo** (no existía en Kotlin) |
| `clic_consulta_impuesto` | consulta de impuesto | comunes¹, `impuesto_id` | antes mandaba el objeto de ruta |
| `clic_psv` | pago sin validación | comunes¹, `impuesto_id` | ídem |
| `clic_cursos` | cursos | comunes¹, `curso_id` | ídem |
| `clic_venues` | escenarios | comunes¹, `venue_id` | ídem |
| `clic_tramite_inactivo` | trámite "en desarrollo" | comunes¹ | **nuevo**: demanda de trámites aún no habilitados |
| `clic_inicio` | barra inferior → Inicio | `municipio_id` | **Reemplaza `clic_mainScreen`** |
| `clic_noticias` / `clic_portal` / `clic_historial` | barra inferior | `municipio_id` | antes mandaban la URL |
| `login` (estándar) | sesión confirmada | `method`: `correo` / `google` | `ContinueWithGoogle` se mandaba al tocar el botón, entrara o no |
| `inicio_registro` | toca "Registrarse" o Google sin cuenta | `method` | **nuevo**: antes este momento mandaba `sign_up` |
| `sign_up` (estándar) | `createUser` exitoso | `method` | ahora cuenta registros **completados** |

¹ Comunes de trámite: `municipio_id`, `tramite_codigo` (el `code` del catálogo, estable entre
entornos), `tramite_id`, `tramite_nombre` (máx. 100).

Los nombres `clic_*` de trámites se mantienen para no cortar las series históricas de GA4.
Para ver `tramite_codigo`, `tramite_nombre`, `url_dominio` e `impuesto_id` en informes, registrarlos
como **dimensiones personalizadas de evento**.

### No portado a propósito

- `ContinueAsGuest`: el flujo Flutter no tiene botón "Continuar como invitado".

### Ojo: `continue_as_guess` no sale del código

Aparece en cada arranque de la app (`EES logging created event` en logcat): es una regla de
**"Crear evento"** de la consola de GA4/Firebase, marcada como **conversión**. Como se dispara al
abrir la app y no al continuar como invitado, esa conversión está inflada. Revisarla en la consola.

### Verificación en dispositivo (2026-10-19, servidor de pruebas)

Llegaron con sus parámetros: `seleccion_municipio`, `fcm_subscribed`, propiedades `municipio` /
`municipio_id`, `clic_consulta_impuesto`, `clic_url_directa` (redes y portales tributarios),
`clic_pqrds`, `clic_cursos`, `clic_venues`, `clic_certificado`, los cuatro de la barra inferior y
`login` con correo. Sin probar en dispositivo: `clic_psv`, `clic_boton_panico`,
`clic_navegacion_nativa`, `clic_tramite_inactivo`, `login` con Google, `inicio_registro`, `sign_up`.

## Próximas fases (propuesta)

- **Fase 1 — embudo de pago integrado:** consulta enviada → resultado (encontrado / sin deuda /
  error) → pasarela abierta → verificación → estado final; `purchase` con `value` en COP cuando
  el backend confirma aprobado.
- **Fase 2 — portales externos:** detectar el regreso a la app (tiempo fuera) y microencuesta de
  1 toque ("¿Pudiste pagar?").
