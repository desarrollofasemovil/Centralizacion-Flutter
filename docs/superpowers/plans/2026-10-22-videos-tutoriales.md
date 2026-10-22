# Videos tutoriales — plan

Fecha: 2026-10-22 · Épica FSM-4 · Decidido con Brayan.

## Objetivo

Que quien tenga dificultad para llegar a pagar (sobre todo adultos mayores) pueda ver
cómo se hace, sin salir de la app. Complementa el tutorial de primer uso
([`2026-10-21-tutorial-primer-uso.md`](2026-10-21-tutorial-primer-uso.md)).

## Decisiones

| Tema | Decisión |
|---|---|
| Material | Los dos videos ya publicados en el canal de 1cero1 (lista «Tutoriales TramiApp», 2026-01-13), grabados con la app Kotlin; los pasos coinciden con Flutter salvo los recordatorios. |
| Reproductor | Dentro de la app, con el reproductor oficial de YouTube en un WebView (`youtube_player_iframe` 6.0.2). Sin enviar a la app de YouTube. |
| Pagos (`8K_o2pC19qY`, narrado; antes `S8lCwQrrcZo`) | Los 3 métodos (consulta en la app, PSV y portal externo). En Bienvenida (signo `?` blanco, sin círculo, fijo arriba a la derecha, con punto de notificación y latido hasta que se abre el video; al lado, el globo «¿Necesitas ayuda? Mira un video tutorial» se ve 5 s y se va solo, y deja de salir al cerrarlo con la × o al abrir el video) y en Ayuda y Soporte. Sin «Iniciar sesión» en Bienvenida. |
| Trámites (`YQQfugIjP6U`) | Cursos y reserva de espacios. Solo en Ayuda y solo si la alcaldía tiene cursos o reservas: su parte de PQRSD muestra solo la anónima, así que no se ofrece por tener PQRSDF. |
| Configuración | Remote Config `tutorial_videos` (interruptor y lista), con estos dos como valor por defecto. Un video nuevo (p. ej. PQRSDF) se agrega sin sacar versión. |
| Reproducción | No arranca sola; subtítulos e interfaz en español; al terminar, solo videos del canal. Girar el celular lo pone en pantalla completa (Android). |
| Analítica | `video_tutorial_abierto`, `video_tutorial_cerrado` (con `porcentaje` y `completo`), en `docs/ANALITICA_EVENTOS.md` Fase 5. |

## Pendiente

- **Narración:** los videos traen el paso a paso escrito en la imagen, pero **no tienen voz**
  (Brayan, 2026-10-22, ya con acceso a YouTube Studio del canal). Subtítulos que repitan ese texto
  aportan poco; lo que falta es una voz que narre. Opciones: texto a voz en español de Clipchamp
  (gratis en Windows 11) o una voz real (comunicaciones o la alcaldía). El guion sale de los textos del
  video; Claude puede armarlo con tiempos a partir del MP4 original (descargable desde YouTube Studio).
  YouTube no deja reemplazar el archivo: el video narrado se sube como nuevo y se cambia su `youtubeId`
  en Remote Config `tutorial_videos`, sin versión nueva de la app.
- **iOS:** el `Info.plist` solo permite vertical, así que el video no gira a horizontal. Decidir si se
  agrega horizontal para iPhone (y se fija vertical en el resto de la app) cuando se pruebe en iOS.
- Video de PQRSDF completa (identificada y anónima), si se graba: entra por Remote Config.

## Estado

- PR (rama `feat/videos-tutoriales`): en curso.
