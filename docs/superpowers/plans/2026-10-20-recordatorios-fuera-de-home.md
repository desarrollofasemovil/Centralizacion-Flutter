# Recordatorios: sacarlos de la Home y ofrecerlos en contexto

> Fecha: 2026-10-20 · Épica: FSM-4 Centralización

## Por qué

La sección de Recordatorios de la Home prácticamente no se usa (no hay datos: el
uso es casi nulo). Para crear uno el ciudadano tiene que inventar un nombre, elegir
un trámite, una fecha y una hora, sin ningún motivo concreto en ese momento. Además,
sin sesión el botón "+" queda deshabilitado sin explicar por qué.

La idea: **ofrecer el recordatorio cuando hay una razón** (una factura con fecha
límite, un pago recién hecho) y darle un lugar propio, fuera de la Home.

## Restricción que condiciona todo

Los recordatorios se guardan en el backend **por usuario** (`api/Reminders`, con
`idUser`), y la notificación local usa el id que devuelve el backend. Por eso:

- Hace falta **sesión real** (`loginStatus == true`). El invitado (datos sin cuenta,
  `loginStatus: false`) cuenta como sin sesión.
- No se crean recordatorios "solo locales" para invitados: se perderían y no
  aparecerían en "Mis recordatorios" al iniciar sesión.

## Pasos

### Paso 1 — "Recordarme" en cada factura ✅ (PR #39)

En los resultados de la consulta de impuesto, cada factura vigente ofrece
**"Recordarme antes del vencimiento"**.

- Se muestra solo si la fecha límite es **posterior a hoy** y el impuesto
  corresponde a un trámite del municipio (el backend exige `idProcedureMunicipality`).
- **Con sesión:** abre el modal de creación ya lleno: nombre `Pagar <impuesto>`,
  trámite, fecha = fecha límite, 8:00, aviso **1 día antes** (o a la hora, si un día
  antes ya pasó). El ciudadano solo confirma.
- **Sin sesión o invitado:** un diálogo explica que el recordatorio se guarda en su
  cuenta y ofrece iniciar sesión; al volver con sesión, sigue directo al modal lleno.
- El aviso de "recordatorio creado" deja de depender de que la Home esté montada
  (`ReminderToastListener`): se ve en la pantalla que esté al frente.
- Analítica nueva (`recordatorio_iniciado`, `recordatorio_creado`) para medir por
  fin el uso. Ver `docs/ANALITICA_EVENTOS.md`.

### Paso 2 — Pantalla "Mis recordatorios" y fuera de la Home ✅ (PR #40)

- Pantalla propia (`RemindersScreen`, ruta `/municipality/:id/reminders`) con la
  lista: próximos primero, cuándo vencen ("mañana", "en 4 días"), vencidos al
  final; crear (botón fijo abajo) y eliminar con confirmación; desliza para
  actualizar.
- Entrada desde el menú lateral ("Mis recordatorios"). El acceso desde Historial
  queda descartado por ahora.
- `RemindersSection` sale de la Home (se borra junto con `SwipeUpDismissBox`, que
  solo usaba ella). En su lugar, `UpcomingReminderBanner`: aviso breve si hay un
  recordatorio en los próximos 7 días; nada si no hay. Al tocarlo abre la pantalla.
- Sin sesión o invitado: tarjeta que explica el beneficio y ofrece iniciar sesión.
- Preferencia `remindersIsVisible` ("Recordatorios Push" en Configuración): ahora
  apaga el aviso de la Home.
- El modal tiene selector de antelación ("Avisarme").
- Analítica: `recordatorios_abiertos` (`entrada`) y el origen `pantalla`.

### Paso 3 — Ofrecerlo después de pagar ✅ (PR #41)

No existe una pantalla de "pago aprobado": "Verificar estado" lleva al Historial y la
aprobación se detecta en segundo plano (donde además se pide la reseña de la tienda).
Decisión de Brayan (2026-10-21):

- **Dónde:** botón **"Recordarme el próximo pago"** en las tarjetas del Historial, solo
  en pagos **APROBADOS** de un impuesto del municipio actual (no certificados ni pagos
  de otra alcaldía: el `idimpuesto` se repite entre municipios). Siempre disponible,
  no compite con la reseña y sirve también para pagos viejos.
- **Fecha:** no hay una periodicidad única (el predial es anual con cuotas según el
  municipio; el ICA, anual o bimestral según el acuerdo), así que el modal ofrece
  **"¿Cuándo vuelve a vencer?" → En 3 meses / En 6 meses / En 1 año**, contado desde
  la fecha del pago (desde hoy si esa fecha ya pasó). Viene en 1 año y con aviso
  **1 semana antes**, porque la fecha es una estimación; el ciudadano puede ajustarla
  en "Fecha".
- Sin sesión: el mismo diálogo de la factura (`ensureReminderSession`).
- Analítica: origen `pago`.
- Sigue pendiente confirmar la periodicidad con el área tributaria: si se conoce por
  impuesto, la opción por defecto podría venir de ahí.

### Descartado

- Sugerencias por calendario tributario: no tenemos el calendario de todos los
  municipios.
