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

### Paso 1 — "Recordarme" en cada factura ✅ (este cambio)

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

### Paso 2 — Pantalla "Mis recordatorios" y fuera de la Home

- Pantalla propia con la lista (tarjetas actuales), crear y eliminar.
- Entrada desde el menú lateral (y evaluar un acceso desde Historial).
- Quitar `RemindersSection` de la Home. En su lugar, solo un aviso breve cuando hay
  un recordatorio próximo ("Tienes un recordatorio mañana"); nada si no hay.
- Sin sesión: la pantalla explica el beneficio y ofrece iniciar sesión (reemplaza el
  "+" deshabilitado).
- Decidir qué pasa con la preferencia `remindersIsVisible` (hoy oculta la sección).
- Añadir al modal un selector de antelación (hoy el `offset` existe en el estado pero
  no en la UI).

### Paso 3 — Ofrecerlo después de pagar

- En la pantalla de pago aprobado: "¿Quieres que te avisemos cuando vuelva a vencer?".
- **Pendiente de confirmar:** la periodicidad. No hay una única nacional: el predial
  es anual y cada municipio fija su calendario (muchos permiten cuotas), y el ICA
  puede ser anual o bimestral según el acuerdo municipal. Confirmar con el área
  tributaria antes de fijar reglas.
- Propuesta mientras tanto: que el ciudadano elija ("en 3 meses", "en 6 meses",
  "en 1 año") en vez de suponer la periodicidad.

### Descartado

- Sugerencias por calendario tributario: no tenemos el calendario de todos los
  municipios.
