# Tutorial de primer uso — plan

Fecha: 2026-10-21 · Épica FSM-4 · Decidido con Brayan (sesión de preguntas).

## Objetivo

Que quien abre la app por primera vez entienda qué puede hacer en su alcaldía:
lo que ya existía (consulta y pago de impuestos, trámites) y lo nuevo
(recordatorios en la factura, "Mis recordatorios", "Recordarme el próximo pago",
guía de PQRDS). La meta medible es que suba el uso de recordatorios, que hoy es
casi nulo.

## Decisiones

| Tema | Decisión |
|---|---|
| Formato | Carrusel de tarjetas a pantalla completa, solo informativas (sin botón "Ir"). |
| Visual | Composición de íconos con el color primario de la alcaldía **+ recortes de capturas reales** (no pantallas completas). Diseño primero en Claude Design. |
| Cuándo | Al llegar a la Home por primera vez, ya con el municipio elegido. Una vez por instalación; cambiar de municipio no lo repite. |
| Quién | Todos en esta versión: quien actualiza desde la app Kotlin entra como nuevo (además la API nueva cierra la sesión de todos). |
| Omitir | Siempre visible. "Atrás" = tarjeta anterior; en la primera, omitir. |
| Volver a verlo | Botón "Ver tutorial de la app" en Ayuda y Soporte. |
| Contenido | Estructura e ilustraciones en la app; en Remote Config un interruptor y los textos (con valores por defecto en la app). |
| Textos | Los propone Claude en el diseño; Brayan los ajusta. |
| Datos personales | Las capturas se toman tal cual y en el diseño se reemplazan por datos ficticios. |
| Analítica | `tutorial_iniciado`, `tutorial_paso_visto`, `tutorial_completado`, `tutorial_omitido` (con el paso), en `docs/ANALITICA_EVENTOS.md`. |
| Novedades | Pospuesto a la siguiente versión (carrusel con id por paquete). En esta versión nadie viene de una versión Flutter. |

## Tarjetas

Las de módulos solo salen si la alcaldía los tiene. "Nativo" = el impuesto se
consulta/paga en la app; "portal" = `integrationType` es una URL.

1. **Bienvenida a {municipio}** — siempre.
2. **Impuestos** — con ≥1 impuesto nativo: consulta, factura y pago por PSE. Si
   todos son por portal: "Paga en el portal oficial de la alcaldía" (aviso de
   redirección).
3. **Recordatorios** — con impuestos nativos: "Recordarme" en la factura y "Mis
   recordatorios" en el menú. Solo portal: crearlos desde "Mis recordatorios".
4. **Tus trámites** — certificados, PQRD, cursos, escenarios… solo los que haya.
5. **Guía de PQRDS** — qué es cada letra y anónima vs. identificada. Si hay PQRD.
6. **Historial de pagos** — "Recordarme el próximo pago" solo con impuestos
   nativos (un pago en portal externo nunca llega al historial).
7. **Crea tu cuenta** — solo sin sesión: Iniciar sesión / Crear cuenta / Ahora no.
   Métodos según la hoja de login (Apple ID cuando exista).

## Pasos

### Paso 0 — Capturas

Municipio de pruebas **ID 81 "Municipio"** (Antioquia, servidor de pruebas, tema
neutro): Industria (PSV), Predial (nativo), Declaración ICA (nativo), Retención de
ICA (portal externo), PQRDS, Certificados, Redes sociales. Sin servicios públicos,
cursos ni reservas.

- Por adb en el celular de pruebas, sin que Brayan lo use mientras tanto.
- Guardar en `docs/onboarding/capturas/` con un `README.md` índice (pantalla → archivo).
- Lista: bienvenida y selección; Home desplegada/recogida, menú lateral, aviso de
  recordatorio próximo; cada trámite (formulario y resultado: facturas con
  "Recordarme", modal del recordatorio, aviso de redirección del portal, PQRDS
  elección/anónima/identificada, certificados, redes); Mis recordatorios vacía y
  con datos; Historial con pago aprobado y "Recordarme el próximo pago"; Ayuda y
  Soporte; login y registro.
- Orden: primero lo que necesita sesión; después cerrar sesión para login,
  registro, bienvenida y selección. Brayan vuelve a iniciar sesión al final.
- Recordatorios de prueba que se creen se borran al terminar.

### Paso 1 — Diseño en Claude Design

Tarjetas (opción íconos + color de la alcaldía, con recortes de capturas), textos
propuestos, datos ficticios y la entrada en Ayuda. Aprobación de Brayan antes de
codificar.

### Paso 2 — PR del tutorial

Componente de carrusel, tarjetas dinámicas por módulo y por canal, marca de
"visto" en preferencias, Remote Config, botón en Ayuda, analítica y tests.

## Estado

- Paso 0 ✅ (2026-10-21): 39 capturas en `docs/onboarding/capturas/` con índice.
  Sin capturar: pasarela PSE y portal externo (el navegador tiene bloqueo de apps
  de MIUI; con sesión el portal se abre directo, sin aviso de redirección).
  Queda en el historial del municipio 81 un pago de prueba COMENZADA ($7.899.874).
- Paso 1 ✅ (2026-10-22): diseño hecho en Claude Design (plantilla "Mobile app
  design", sin design system), con el prompt que define tarjetas 1, 2A/2B, 3A/3B,
  4, 5 (PQRSDF con la F de felicitaciones), 6A/6B y 7, recorridos para dos
  alcaldías, theming con azul #005B8C y verde #2E7D32, botón en Ayuda y hoja de
  especificaciones.
- Paso 2 ✅ (PR #43, 2026-10-22): implementado en
  `lib/features/tutorial/` a partir del diseño (archivos `Tutorial Trami.dc.html` y
  `TarjetaTutorial.dc.html`). Carrusel, tarjetas por módulo y canal, flag
  `tutorial_primer_uso_visto`, Remote Config `tutorial_config`, botón en Ayuda,
  analítica (`docs/ANALITICA_EVENTOS.md` Fase 4) y tests. En el celular (municipio 81,
  servidor de pruebas, sin sesión) salió solo al llegar a la Home con el recorrido
  `1-2A-3A-4-5-6A-7`, ida y vuelta por las 7 tarjetas sin errores; el cierre no quedó
  en el log (se cayó el adb). Brayan lo aprobó.
  - Diferencias con la hoja de especificaciones: el flag es **por instalación**, no
    "por alcaldía" (decisión del plan), y se guarda **al abrir** el tutorial, no solo
    al omitir o terminar. Sin impuestos no sale la tarjeta 2. La 5 solo sale con la
    PQRSDF de la app (la guía habla de radicado y anónima). El botón de atrás es el
    compartido `AppBackButton` (35 dp) dentro de un área táctil de 48 dp.

## Detalles encontrados al capturar (corregir en el PR del tutorial)

1. ✅ Aviso de consulta sin resultados: "No se encontrarón facturas" → "encontraron".
2. ✅ Historial: el separador sobre "Recordarme el próximo pago" sale como una línea
   negra fuerte (`Divider(height: 20)` del PR #41); debe ser gris suave.
3. ✅ PSV paso 3: los títulos "Paso 1/2/3" quedan medio tapados bajo la barra
   superior cuando la pantalla viene desplazada (por el teclado del paso 2).
4. ✅ Plan de recordatorios: el paso 3 todavía dice "✅ (en revisión)"; cambiarlo a
   "✅ (PR #41)".

## Fuera de este plan

- Novedades (siguiente versión).
- Videos tutoriales de YouTube (pagos; cursos y reservas) en Welcome y Ayuda: ver
  `2026-10-22-videos-tutoriales.md`.
- Cierre de sesión general y nuevo login con la API nueva (Google, nativo, Apple ID).
