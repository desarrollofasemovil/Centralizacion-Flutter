-- =============================================================================
-- Consultas de BigQuery — Analítica de Trami App (Centralización)
-- =============================================================================
-- Exportación diaria de GA4/Firebase vinculada el 2026-10-19 al proyecto
-- `betaappcentralizate` (sandbox: cada tabla diaria expira a los 60 días).
-- Catálogo de eventos y parámetros: docs/ANALITICA_EVENTOS.md
--
-- CÓMO USARLAS
-- 1. Reemplaza `analytics_XXXXXXXXX` por el dataset real (panel izquierdo de
--    BigQuery: `analytics_` + el id de la propiedad de GA4).
-- 2. Ajusta las fechas de cada consulta (formato AAAAMMDD de `_TABLE_SUFFIX`).
-- 3. Copia el BLOQUE DE FUNCIONES + UNA consulta y ejecútalas juntas: las
--    funciones TEMP solo existen dentro de la misma ejecución.
--
-- OJO CON LOS DATOS DE PRUEBA
-- Los builds de desarrollo (servidor de pruebas) mandan al MISMO proyecto de
-- Firebase. Para que las pruebas no se mezclen con los ciudadanos, cada
-- consulta excluye los dispositivos de QA listados en `pruebas_excluidas`.
-- Agrega ahí el `user_pseudo_id` de cada celular de pruebas (la consulta 0
-- ayuda a encontrarlo).
--
-- No se han ejecutado todavía contra datos reales (no había exportación al
-- escribirlas): la primera vez, revisa que los totales cuadren con GA4.
-- =============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- BLOQUE DE FUNCIONES (copiar siempre junto con la consulta)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE TEMP FUNCTION p_str(params ANY TYPE, k STRING) AS (
  (SELECT COALESCE(value.string_value, CAST(value.int_value AS STRING))
   FROM UNNEST(params) WHERE key = k)
);
CREATE TEMP FUNCTION p_int(params ANY TYPE, k STRING) AS (
  (SELECT COALESCE(value.int_value, CAST(value.double_value AS INT64),
                   SAFE_CAST(value.string_value AS INT64))
   FROM UNNEST(params) WHERE key = k)
);
CREATE TEMP FUNCTION p_num(params ANY TYPE, k STRING) AS (
  (SELECT COALESCE(value.double_value, value.float_value,
                   CAST(value.int_value AS FLOAT64))
   FROM UNNEST(params) WHERE key = k)
);
-- Propiedad de usuario `municipio` (nombre normalizado, p. ej. El_Carmen_de_Viboral).
CREATE TEMP FUNCTION u_str(props ANY TYPE, k STRING) AS (
  (SELECT value.string_value FROM UNNEST(props) WHERE key = k)
);


-- ─────────────────────────────────────────────────────────────────────────────
-- 0. Encontrar los dispositivos de prueba (para la lista de exclusión)
-- ─────────────────────────────────────────────────────────────────────────────
-- Los celulares de QA usan el servidor de pruebas: sus municipios incluyen
-- "test" y aparecen en los días de pruebas. Revisa el modelo y la versión.
SELECT
  user_pseudo_id,
  device.mobile_model_name AS modelo,
  app_info.version AS version_app,
  MIN(PARSE_DATE('%Y%m%d', event_date)) AS primer_dia,
  COUNT(*) AS eventos,
  STRING_AGG(DISTINCT u_str(user_properties, 'municipio'), ', ') AS municipios
FROM `betaappcentralizate.analytics_XXXXXXXXX.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20261019' AND FORMAT_DATE('%Y%m%d', CURRENT_DATE())
GROUP BY 1, 2, 3
HAVING LOGICAL_OR(u_str(user_properties, 'municipio') = 'test')
ORDER BY eventos DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Encuesta de portales externos: respuestas por municipio y trámite
-- ─────────────────────────────────────────────────────────────────────────────
-- Responde la B ("¿pagó?") para los portales externos, como proporción
-- autorreportada. Con menos de 30–50 respuestas por fila, los % no son estables.
WITH pruebas_excluidas AS (
  SELECT user_pseudo_id FROM UNNEST([
    'REEMPLAZAR_user_pseudo_id_celular_QA'
  ]) AS user_pseudo_id
),
respuestas AS (
  SELECT
    p_int(event_params, 'municipio_id') AS municipio_id,
    u_str(user_properties, 'municipio') AS municipio,
    p_str(event_params, 'tramite_nombre') AS tramite,
    p_str(event_params, 'respuesta') AS respuesta
  FROM `betaappcentralizate.analytics_XXXXXXXXX.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20261101' AND '20261231'
    AND event_name = 'encuesta_portal_respuesta'
    AND user_pseudo_id NOT IN (SELECT user_pseudo_id FROM pruebas_excluidas)
)
SELECT
  municipio_id,
  ANY_VALUE(municipio) AS municipio,
  tramite,
  COUNT(*) AS respuestas,
  COUNTIF(respuesta = 'pague') AS pague,
  COUNTIF(respuesta = 'consulte_no_pague') AS consulte_no_pague,
  COUNTIF(respuesta = 'problema') AS problema,
  COUNTIF(respuesta = 'solo_mirando') AS solo_mirando,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(respuesta = 'pague'), COUNT(*)), 1) AS pct_pague,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(respuesta = 'problema'), COUNT(*)), 1) AS pct_problema
FROM respuestas
GROUP BY municipio_id, tramite
ORDER BY respuestas DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Tasa de respuesta de la encuesta por mes
-- ─────────────────────────────────────────────────────────────────────────────
-- Si baja del ~10 %, la encuesta molesta o sale en mal momento.
WITH pruebas_excluidas AS (
  SELECT user_pseudo_id FROM UNNEST([
    'REEMPLAZAR_user_pseudo_id_celular_QA'
  ]) AS user_pseudo_id
)
SELECT
  FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS mes,
  COUNTIF(event_name = 'encuesta_portal_mostrada') AS mostradas,
  COUNTIF(event_name = 'encuesta_portal_respuesta') AS respondidas,
  COUNTIF(event_name = 'encuesta_portal_descartada') AS descartadas,
  ROUND(100 * SAFE_DIVIDE(
    COUNTIF(event_name = 'encuesta_portal_respuesta'),
    COUNTIF(event_name = 'encuesta_portal_mostrada')), 1) AS tasa_respuesta_pct
FROM `betaappcentralizate.analytics_XXXXXXXXX.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20261101' AND '20261231'
  AND event_name IN ('encuesta_portal_mostrada', 'encuesta_portal_respuesta',
                     'encuesta_portal_descartada')
  AND user_pseudo_id NOT IN (SELECT user_pseudo_id FROM pruebas_excluidas)
GROUP BY mes
ORDER BY mes;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Problemas por portal (dominio) y motivo
-- ─────────────────────────────────────────────────────────────────────────────
-- Responde la C ("¿tuvo problemas?"): sirve para reportarle al municipio que su
-- portal falla, con datos.
WITH pruebas_excluidas AS (
  SELECT user_pseudo_id FROM UNNEST([
    'REEMPLAZAR_user_pseudo_id_celular_QA'
  ]) AS user_pseudo_id
)
SELECT
  p_str(event_params, 'url_dominio') AS portal,
  ANY_VALUE(u_str(user_properties, 'municipio')) AS municipio,
  p_str(event_params, 'motivo') AS motivo,
  COUNT(*) AS veces
FROM `betaappcentralizate.analytics_XXXXXXXXX.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20261101' AND '20261231'
  AND event_name = 'encuesta_portal_respuesta'
  AND p_str(event_params, 'respuesta') = 'problema'
  AND user_pseudo_id NOT IN (SELECT user_pseudo_id FROM pruebas_excluidas)
GROUP BY portal, motivo
ORDER BY portal, veces DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Credibilidad de "Sí, pagué" según el tiempo fuera
-- ─────────────────────────────────────────────────────────────────────────────
-- Un "pagué" con menos de 15 s en el portal es poco creíble; con 3–10 min, muy
-- creíble. Úsala para decidir qué respuestas cuentan en la estimación (5).
WITH pruebas_excluidas AS (
  SELECT user_pseudo_id FROM UNNEST([
    'REEMPLAZAR_user_pseudo_id_celular_QA'
  ]) AS user_pseudo_id
)
SELECT
  p_str(event_params, 'rango_tiempo') AS rango_tiempo,
  COUNT(*) AS respuestas,
  COUNTIF(p_str(event_params, 'respuesta') = 'pague') AS pague,
  ROUND(100 * SAFE_DIVIDE(
    COUNTIF(p_str(event_params, 'respuesta') = 'pague'), COUNT(*)), 1) AS pct_pague
FROM `betaappcentralizate.analytics_XXXXXXXXX.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20261101' AND '20261231'
  AND event_name = 'encuesta_portal_respuesta'
  AND user_pseudo_id NOT IN (SELECT user_pseudo_id FROM pruebas_excluidas)
GROUP BY rango_tiempo
ORDER BY CASE rango_tiempo
  WHEN 'menos_15s' THEN 1 WHEN '15_60s' THEN 2 WHEN '1_3min' THEN 3
  WHEN '3_10min' THEN 4 ELSE 5 END;


-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Estimación de pagos en portales externos por municipio y mes
-- ─────────────────────────────────────────────────────────────────────────────
-- pagos_estimados = visitas al portal de impuestos × % "pagué" de la encuesta.
-- Es una ESTIMACIÓN (muestra autorreportada): úsala como tendencia, no como
-- cifra de recaudo. El monto real solo llega cruzando con la pasarela.
WITH pruebas_excluidas AS (
  SELECT user_pseudo_id FROM UNNEST([
    'REEMPLAZAR_user_pseudo_id_celular_QA'
  ]) AS user_pseudo_id
),
base AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS mes,
    p_int(event_params, 'municipio_id') AS municipio_id,
    u_str(user_properties, 'municipio') AS municipio,
    event_name,
    p_str(event_params, 'respuesta') AS respuesta
  FROM `betaappcentralizate.analytics_XXXXXXXXX.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20261101' AND '20261231'
    AND event_name IN ('portal_externo_regreso', 'encuesta_portal_respuesta')
    AND user_pseudo_id NOT IN (SELECT user_pseudo_id FROM pruebas_excluidas)
)
SELECT
  mes,
  municipio_id,
  ANY_VALUE(municipio) AS municipio,
  COUNTIF(event_name = 'portal_externo_regreso') AS visitas_portal,
  COUNTIF(event_name = 'encuesta_portal_respuesta') AS respuestas,
  ROUND(100 * SAFE_DIVIDE(
    COUNTIF(respuesta = 'pague'),
    COUNTIF(event_name = 'encuesta_portal_respuesta')), 1) AS pct_pague,
  ROUND(COUNTIF(event_name = 'portal_externo_regreso') * SAFE_DIVIDE(
    COUNTIF(respuesta = 'pague'),
    COUNTIF(event_name = 'encuesta_portal_respuesta'))) AS pagos_estimados
FROM base
GROUP BY mes, municipio_id
ORDER BY mes, visitas_portal DESC;
-- Nota: `portal_externo_regreso` incluye trámites que no son impuestos y solo
-- existe en Android (en iOS solo hay `portal_externo_abierto`).


-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Recaudo por la pasarela integrada de la app, por municipio y mes
-- ─────────────────────────────────────────────────────────────────────────────
-- Pagos APROBADOS confirmados por el backend (`purchase`). Deduplicado por
-- `transaction_id` (= id del historial de pagos), por si llegara repetido.
WITH pruebas_excluidas AS (
  SELECT user_pseudo_id FROM UNNEST([
    'REEMPLAZAR_user_pseudo_id_celular_QA'
  ]) AS user_pseudo_id
),
compras AS (
  SELECT
    FORMAT_DATE('%Y-%m', PARSE_DATE('%Y%m%d', event_date)) AS mes,
    p_int(event_params, 'municipio_id') AS municipio_id,
    u_str(user_properties, 'municipio') AS municipio,
    p_str(event_params, 'impuesto_id') AS impuesto_id,
    p_str(event_params, 'transaction_id') AS transaction_id,
    COALESCE(ecommerce.purchase_revenue, p_num(event_params, 'value')) AS valor_cop
  FROM `betaappcentralizate.analytics_XXXXXXXXX.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20261101' AND '20261231'
    AND event_name = 'purchase'
    AND user_pseudo_id NOT IN (SELECT user_pseudo_id FROM pruebas_excluidas)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY transaction_id ORDER BY event_timestamp) = 1
)
SELECT
  mes,
  municipio_id,
  ANY_VALUE(municipio) AS municipio,
  COUNT(*) AS pagos_aprobados,
  SUM(valor_cop) AS recaudo_cop,
  ROUND(AVG(valor_cop)) AS ticket_promedio_cop
FROM compras
GROUP BY mes, municipio_id
ORDER BY mes, recaudo_cop DESC;


-- ─────────────────────────────────────────────────────────────────────────────
-- 7. Embudo de la pasarela integrada por municipio (usuarios únicos)
-- ─────────────────────────────────────────────────────────────────────────────
-- Responde la A ("¿consultó su factura?") y la B ("¿pagó?") para los trámites
-- con pasarela dentro de la app.
WITH pruebas_excluidas AS (
  SELECT user_pseudo_id FROM UNNEST([
    'REEMPLAZAR_user_pseudo_id_celular_QA'
  ]) AS user_pseudo_id
),
pasos AS (
  SELECT
    user_pseudo_id,
    p_int(event_params, 'municipio_id') AS municipio_id,
    u_str(user_properties, 'municipio') AS municipio,
    CASE
      WHEN event_name = 'consulta_impuesto_enviada' THEN 1
      WHEN event_name = 'consulta_impuesto_resultado'
           AND p_str(event_params, 'resultado') = 'encontrado' THEN 2
      WHEN event_name = 'pasarela_abierta' THEN 3
      WHEN event_name = 'purchase' THEN 4
    END AS paso
  FROM `betaappcentralizate.analytics_XXXXXXXXX.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20261101' AND '20261231'
    AND event_name IN ('consulta_impuesto_enviada', 'consulta_impuesto_resultado',
                       'pasarela_abierta', 'purchase')
    AND user_pseudo_id NOT IN (SELECT user_pseudo_id FROM pruebas_excluidas)
)
SELECT
  municipio_id,
  ANY_VALUE(municipio) AS municipio,
  COUNT(DISTINCT IF(paso = 1, user_pseudo_id, NULL)) AS consultaron,
  COUNT(DISTINCT IF(paso = 2, user_pseudo_id, NULL)) AS encontraron_factura,
  COUNT(DISTINCT IF(paso = 3, user_pseudo_id, NULL)) AS abrieron_pasarela,
  COUNT(DISTINCT IF(paso = 4, user_pseudo_id, NULL)) AS pagaron
FROM pasos
WHERE paso IS NOT NULL
GROUP BY municipio_id
ORDER BY consultaron DESC;
-- Nota: el PSV y los certificados entran directo en `pasarela_abierta`, así que
-- `abrieron_pasarela` puede ser mayor que `encontraron_factura`.


-- ─────────────────────────────────────────────────────────────────────────────
-- 8. Abandono antes de salir al portal externo
-- ─────────────────────────────────────────────────────────────────────────────
-- Toques en el trámite (`clic_url_directa`) vs. portales que de verdad se
-- abrieron: la diferencia es quien abandona en el formulario de datos o en el
-- aviso de sitio externo. Excluye las redes sociales (sin tramite_codigo de
-- catálogo: empiezan por "social:").
WITH pruebas_excluidas AS (
  SELECT user_pseudo_id FROM UNNEST([
    'REEMPLAZAR_user_pseudo_id_celular_QA'
  ]) AS user_pseudo_id
)
SELECT
  p_int(event_params, 'municipio_id') AS municipio_id,
  ANY_VALUE(u_str(user_properties, 'municipio')) AS municipio,
  p_str(event_params, 'tramite_nombre') AS tramite,
  COUNTIF(event_name = 'clic_url_directa') AS toques,
  COUNTIF(event_name = 'portal_externo_abierto') AS abiertos,
  ROUND(100 * (1 - SAFE_DIVIDE(
    COUNTIF(event_name = 'portal_externo_abierto'),
    COUNTIF(event_name = 'clic_url_directa'))), 1) AS pct_abandono
FROM `betaappcentralizate.analytics_XXXXXXXXX.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20261101' AND '20261231'
  AND event_name IN ('clic_url_directa', 'portal_externo_abierto')
  AND NOT STARTS_WITH(IFNULL(p_str(event_params, 'tramite_codigo'), ''), 'social:')
  AND user_pseudo_id NOT IN (SELECT user_pseudo_id FROM pruebas_excluidas)
GROUP BY municipio_id, tramite
HAVING toques > 0
ORDER BY toques DESC;
