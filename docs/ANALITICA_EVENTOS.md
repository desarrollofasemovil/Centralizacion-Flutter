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

## Fase 1 — embudo del pago por pasarela integrada (2026-10-19)

Mide cuánto pagan realmente los contribuyentes por la pasarela de la app, sin encuestas: el
backend ya guarda estado y monto en el historial de pagos (`GET api/PaymentHistory/User/{id}`).

```
consulta_impuesto_enviada → consulta_impuesto_resultado (encontrado)
  → pasarela_abierta → pago_verificado (aprobado / pendiente / rechazado) → purchase
                     ↘ pago_error (en cualquier paso)
```

El PSV y los certificados entran directo en `pasarela_abierta` (no tienen consulta).

### Eventos

| Evento | Cuándo | Parámetros |
|---|---|---|
| `consulta_impuesto_enviada` | toca "Consultar" (`TaxQueryNotifier`) | `municipio_id`, `impuesto_id`, `entidad_codigo`, `tipo_consulta` (nombre del campo, **nunca** el documento) |
| `consulta_impuesto_resultado` | responde la consulta | `municipio_id`, `impuesto_id`, `resultado` (`encontrado` / `sin_deuda` / `error`); con `encontrado`: `cantidad` y `valor_total` (COP adeudados); con `error`: `motivo` |
| `pasarela_abierta` | se abre la URL de la pasarela («Procesando tu pago») | `municipio_id`, `origen`², `url_dominio` (solo el dominio: la URL trae el token), `impuesto_id` (si se conoce) |
| `pago_verificado` | estado del pago tras sincronizarlo con la pasarela | `municipio_id`, `resultado`³, `estado_id`, `pantalla` (`procesamiento` = botón «Verificar estado»; `historial` = deslizar para refrescar), `valor` (monto del historial), `origen`² (solo desde procesamiento) |
| `purchase` (estándar GA4) | el **backend** confirma el pago aprobado | `value` (monto del historial), `currency: COP`, `transaction_id: hist_<id del historial>`, `municipio_id`, `impuesto_id` |
| `pago_error` | falla algún paso | `municipio_id`, `origen`², `etapa`⁴, `motivo`⁵ |

² `origen`: `consulta_impuesto`, `psv` (pago sin validación) o `certificado`.

³ `resultado` según `idStatusType` del historial (tabla `Availibity` de la API, la misma que
lee `HistoryPayScreen.kt`): 1 APROBADA → `aprobado`, 2 COMENZADA → `pendiente`, 3 FALLIDA y
4 EXPIRADA → `rechazado`; cualquier otro → `desconocido`.

⁴ `etapa`: `registro_historial` (`POST api/PaymentHistory/` rechazado o caído, o faltan datos
para hacerlo), `transaccion` (crear la transacción en la pasarela), `sin_url` (la pasarela
respondió sin URL) o `verificacion` (la sincronización falló o el historial llegó vacío).

⁵ `motivo` es un código corto, nunca el mensaje del error (el de Dio incluye la URL, que lleva el
documento consultado): `timeout`, `sin_conexion`, `http_<código>`, `red`, `cancelado`,
`rechazado_<codeStatus>`, `faltan_datos`, `url_vacia`, `historial_vacio` o el tipo del error.

### Reglas de `purchase`

- **Solo cuando el backend lo confirma.** Nunca al abrir la pasarela ni al volver de ella.
- **Solo en la transición a aprobado:** se manda si el pago estaba en otro estado antes de esta
  sincronización. Si «Verificar estado» encuentra que el último pago ya estaba aprobado (un pago
  viejo, o el registro del nuevo falló), no cuenta una compra.
- **Sin duplicados:** `transaction_id` es el id del historial; GA4 descarta un segundo `purchase`
  con el mismo id. Los pagos que en «Verificar estado» seguían pendientes se cuentan después, al
  refrescar el Historial (`pantalla: historial`).
- Lo que el contribuyente **paga fuera de la app** (portales externos) no aparece aquí: es la
  Fase 2.

### Para los informes

- Registrar como **dimensiones personalizadas de evento**: `resultado`, `origen`, `etapa`,
  `motivo`, `pantalla`, `tipo_consulta`, `entidad_codigo`. Como **métricas**: `valor_total`,
  `valor`, `cantidad`.
- Los ingresos de `purchase` salen solos en *Monetización* (GA4 entiende `value` + `currency`).
- Embudo sugerido (Explorar → Exploración de embudo): `consulta_impuesto_enviada` →
  `consulta_impuesto_resultado` (`resultado = encontrado`) → `pasarela_abierta` → `purchase`,
  desglosado por `municipio`.

### Verificación en dispositivo

**Verificado (2026-10-19):** Brayan recorrió el flujo completo en el celular contra el servidor de
pruebas y los eventos del embudo llegaron con sus parámetros, incluido `purchase` con el monto de la
transacción. Cubierto además por tests unitarios (`test/core/analytics/payment_funnel_analytics_test.dart`,
`test/features/pagos/payment_funnel_analytics_test.dart`).

> Ojo al verificar: un APK compilado desde un worktree sale **sin** `google-services.json`
> (está en `.gitignore`) y Analytics queda apagado (`E/FA Missing google_app_id`). Y el logcat
> `FA-SVC` mezcla eventos de otras apps del celular: filtrar por el pid de la app.

## Fase 2 — portales externos y microencuesta (2026-10-19)

Cuando un trámite manda al portal tributario del municipio (`AbrirUrl` / `AbrirUrlDirecto`), la
app pierde el rastro: Chrome Custom Tabs y Safari View Controller **no exponen la URL** que el
usuario visita (es una garantía de privacidad del navegador). Se mide lo observable — cuánto tiempo
estuvo fuera — y, para los impuestos, se pregunta con una microencuesta de un toque si pudo pagar.
Código: `lib/features/portal_externo/`.

Las redes sociales (categoría `social`) y el WhatsApp del botón de pánico no cuentan como portal.

### Flujo

```
clic_url_directa → [formulario de datos] → [aviso de sitio externo, 3 s]
  → portal_externo_abierto → (usuario en el portal) → portal_externo_regreso
  → encuesta_portal_mostrada → encuesta_portal_respuesta | encuesta_portal_descartada
```

La encuesta sale **al volver a la Home**, solo si: el trámite es un **impuesto**, estuvo fuera
**20 s o más** y no se le preguntó por **ese trámite en ese municipio en los últimos 15 días**. Si
otra pantalla o diálogo está encima de la Home al volver, no sale.

### Eventos

Comunes⁶: `municipio_id`, `tramite_codigo`, `tramite_id`, `tramite_nombre`, `url_dominio`.

| Evento | Cuándo | Parámetros |
|---|---|---|
| `portal_externo_abierto` | el portal se abre de verdad (pasó formulario y aviso) | comunes⁶ |
| `portal_externo_regreso` | vuelve a la app desde el portal | comunes⁶, `segundos_fuera`, `rango_tiempo`⁷, `app_reiniciada` (`si`/`no`) |
| `encuesta_portal_mostrada` | se muestra la encuesta | comunes⁶, `rango_tiempo`⁷ |
| `encuesta_portal_respuesta` | responde | comunes⁶, `rango_tiempo`⁷, `respuesta`⁸, `motivo`⁹ (solo con `problema`) |
| `encuesta_portal_descartada` | la cierra sin terminar | comunes⁶, `paso` (`pregunta` / `motivo`) |

⁶ Los mismos de `clic_url_directa`; `url_dominio` es solo el dominio (la URL del portal puede traer
el documento).

⁷ `rango_tiempo`: `menos_15s`, `15_60s`, `1_3min`, `3_10min`, `mas_10min`.

⁸ `respuesta`: `pague`, `consulte_no_pague`, `problema`, `solo_mirando`.

⁹ `motivo`: `no_encontre_factura`, `pagina_fallo`, `pago_rechazado`, `sin_medio_pago`, `otro`.

### Detalles

- **Android cierra la app con la Custom Tab al frente** (pasó en un Xiaomi a los 20 s). Por eso la
  visita en curso se guarda en `SharedPreferences` (`portal_visit_pending`) y, si el proceso murió,
  se resuelve al volver a montar la Home (`app_reiniciada = si`; el tiempo incluye el reinicio). La
  encuesta solo sale en ese caso si volvió antes de 60 min.
- Solo cuenta como regreso un `resumed` precedido de que la app se ocultara (evita falsos regresos
  por bajar la barra de notificaciones antes de que cargue la pestaña).
- **iOS:** Safari View Controller se presenta dentro de la app (el ciclo de vida no cambia) y
  `flutter_custom_tabs` no expone su `didFinish`. En iOS solo se registra `portal_externo_abierto`;
  regreso y encuesta quedan pendientes de una señal nativa.
- Las respuestas viven **solo en Analytics** (sin endpoint ni datos personales).

### Para los informes

- **Dimensiones de evento:** `respuesta`, `motivo` (ya registrada en la Fase 1), `rango_tiempo`,
  `app_reiniciada`, `paso`. **Métrica:** `segundos_fuera` (unidad: segundos).
- **Tasa de respuesta** = `encuesta_portal_respuesta` / `encuesta_portal_mostrada`.

### Verificación en dispositivo (2026-10-19)

En el Xiaomi contra el servidor de pruebas: visita corta sin encuesta (19 s), visita de 77 s con
encuesta respondida (`problema` → `pagina_fallo`), y proceso matado con la Custom Tab al frente
(`am kill`): al volver a la Home llegó `portal_externo_regreso` con `app_reiniciada = si` y salió
la encuesta; cerrarla con la X registró `encuesta_portal_descartada` (`paso = pregunta`).

## Fase 3 — recordatorios (2026-10-20)

Hasta ahora no se medía nada de Recordatorios y el uso se percibe casi nulo. Estos eventos acompañan
el botón **"Recordarme antes del vencimiento"** de cada factura (plan:
[`superpowers/plans/2026-10-20-recordatorios-fuera-de-home.md`](superpowers/plans/2026-10-20-recordatorios-fuera-de-home.md)).

### Eventos

| Evento | Cuándo | Parámetros |
|---|---|---|
| `recordatorios_abiertos` | abre "Mis recordatorios" | `municipio_id`, `entrada` (`menu` / `aviso_inicio`) |
| `recordatorio_iniciado` | toca "Recordarme" en una factura o "Crear recordatorio" en la pantalla | `municipio_id`, `origen` (`factura` / `pantalla`), `sesion` (`si`/`no`) |
| `recordatorio_creado` | el backend guardó el recordatorio (desde cualquier entrada) | `municipio_id` (si el trámite lo trae), `origen` (`factura` / `pantalla`), `antelacion` (`none`, `oneDay`, …) |

### Para los informes

- **Dimensiones de evento:** `origen`, `sesion`, `antelacion`, `entrada`.
- **Conversión del botón** = `recordatorio_creado` (`origen = factura`) / `recordatorio_iniciado`.
- `sesion = no` seguido de `login` muestra cuántos inician sesión para poder crear el recordatorio.

## BigQuery (vinculado el 2026-10-19)

Exportación **diaria** de Google Analytics desde Firebase al proyecto `betaappcentralizate`, en
**sandbox** (sin facturación): cada tabla `events_AAAAMMDD` **expira a los 60 días**. Para guardar
historial hay que activar la facturación y cambiar la expiración por defecto del dataset antes de
que se borren las primeras tablas.

Consultas listas en [`analitica/consultas_bigquery.sql`](analitica/consultas_bigquery.sql):
encuesta por municipio y trámite, tasa de respuesta, problemas por portal, credibilidad de "pagué"
según el tiempo fuera, estimación de pagos en portales externos, recaudo de `purchase` por
municipio y mes, embudo de la pasarela integrada y abandono antes del portal. Excluyen los celulares
de QA (el servidor de pruebas manda al mismo proyecto de Firebase).

## Próximas fases (propuesta)

- **Cruce con la pasarela (opción 1):** registrar en el backend la salida al portal (usuario,
  municipio, trámite, hora) y cruzarla con las transacciones de la pasarela para conocer pagos y
  montos reales hechos fuera de la app. Requiere endpoint nuevo, acceso a los datos de la pasarela
  y cobertura en la autorización de Habeas Data.
- **iOS:** detectar el cierre de Safari View Controller (delegado nativo) para tener regreso y
  encuesta también en iPhone.
