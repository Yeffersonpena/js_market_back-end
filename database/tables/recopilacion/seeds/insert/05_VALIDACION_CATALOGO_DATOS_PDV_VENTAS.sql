-- =============================================
-- VALIDACION: Catalogo DATOS PDV VENTAS
-- Objetivo: validar consistencia de formulario, secciones,
--           preguntas y opciones luego de los inserts.
-- =============================================

DECLARE @FormularioCodigo VARCHAR(50) = 'DATOS_PDV_VENTAS';
DECLARE @Version INT = 1;
DECLARE @FormularioId INT;

SELECT @FormularioId = id
FROM dbo.RC_FORMULARIO
WHERE codigo = @FormularioCodigo
  AND version = @Version;

SELECT
    'FORMULARIO' AS bloque,
    f.id,
    f.codigo,
    f.nombre,
    f.version,
    f.activo,
    f.fecha_inicio_vigencia,
    f.fecha_fin_vigencia
FROM dbo.RC_FORMULARIO f
WHERE f.id = @FormularioId;

SELECT
    'SECCIONES' AS bloque,
    s.id,
    s.codigo,
    s.titulo,
    s.orden,
    s.activo
FROM dbo.RC_SECCION s
WHERE s.formulario_id = @FormularioId
ORDER BY s.orden;

SELECT
    'RESUMEN_PREGUNTAS_X_SECCION' AS bloque,
    s.codigo AS seccion_codigo,
    s.titulo,
    s.orden AS seccion_orden,
    COUNT(q.id) AS total_preguntas,
    SUM(CASE WHEN q.tipo_respuesta IN ('opcion_unica', 'opcion_multiple', 'si_no') THEN 1 ELSE 0 END) AS preguntas_cerradas,
    SUM(CASE WHEN q.requiere_foto = 1 THEN 1 ELSE 0 END) AS preguntas_con_foto
FROM dbo.RC_SECCION s
LEFT JOIN dbo.RC_PREGUNTA q
    ON q.seccion_id = s.id
WHERE s.formulario_id = @FormularioId
GROUP BY s.codigo, s.titulo, s.orden
ORDER BY s.orden;

SELECT
    'PREGUNTAS' AS bloque,
    s.codigo AS seccion_codigo,
    q.codigo AS pregunta_codigo,
    q.tipo_respuesta,
    q.obligatoria,
    q.requiere_foto,
    q.min_fotos,
    q.max_fotos,
    q.orden,
    q.activo,
    q.texto
FROM dbo.RC_PREGUNTA q
INNER JOIN dbo.RC_SECCION s
    ON s.id = q.seccion_id
WHERE s.formulario_id = @FormularioId
ORDER BY s.orden, q.orden;

-- Validacion 1: preguntas cerradas sin opciones
SELECT
    'ERROR_CERRADA_SIN_OPCION' AS tipo_error,
    s.codigo AS seccion_codigo,
    q.codigo AS pregunta_codigo,
    q.tipo_respuesta,
    q.texto
FROM dbo.RC_PREGUNTA q
INNER JOIN dbo.RC_SECCION s
    ON s.id = q.seccion_id
LEFT JOIN dbo.RC_PREGUNTA_OPCION o
    ON o.pregunta_id = q.id
WHERE s.formulario_id = @FormularioId
  AND q.tipo_respuesta IN ('opcion_unica', 'opcion_multiple', 'si_no')
GROUP BY s.codigo, q.codigo, q.tipo_respuesta, q.texto
HAVING COUNT(o.id) = 0
ORDER BY s.codigo, q.codigo;

-- Validacion 2: preguntas abiertas con opciones cargadas
SELECT
    'ERROR_ABIERTA_CON_OPCION' AS tipo_error,
    s.codigo AS seccion_codigo,
    q.codigo AS pregunta_codigo,
    q.tipo_respuesta,
    COUNT(o.id) AS total_opciones
FROM dbo.RC_PREGUNTA q
INNER JOIN dbo.RC_SECCION s
    ON s.id = q.seccion_id
INNER JOIN dbo.RC_PREGUNTA_OPCION o
    ON o.pregunta_id = q.id
WHERE s.formulario_id = @FormularioId
  AND q.tipo_respuesta NOT IN ('opcion_unica', 'opcion_multiple', 'si_no')
GROUP BY s.codigo, q.codigo, q.tipo_respuesta
ORDER BY s.codigo, q.codigo;

-- Validacion 3: preguntas con foto mal configuradas
SELECT
    'ERROR_FOTO_CONFIG' AS tipo_error,
    s.codigo AS seccion_codigo,
    q.codigo AS pregunta_codigo,
    q.requiere_foto,
    q.min_fotos,
    q.max_fotos
FROM dbo.RC_PREGUNTA q
INNER JOIN dbo.RC_SECCION s
    ON s.id = q.seccion_id
WHERE s.formulario_id = @FormularioId
  AND (
      q.min_fotos < 0
      OR q.max_fotos < 0
      OR q.max_fotos < q.min_fotos
      OR (q.requiere_foto = 1 AND q.min_fotos = 0)
  )
ORDER BY s.codigo, q.codigo;

-- Validacion 4: duplicidad de orden por seccion
SELECT
    'ERROR_ORDEN_DUPLICADO' AS tipo_error,
    s.codigo AS seccion_codigo,
    q.orden,
    COUNT(*) AS cantidad
FROM dbo.RC_PREGUNTA q
INNER JOIN dbo.RC_SECCION s
    ON s.id = q.seccion_id
WHERE s.formulario_id = @FormularioId
GROUP BY s.codigo, q.orden
HAVING COUNT(*) > 1
ORDER BY s.codigo, q.orden;

SELECT
    'OPCIONES' AS bloque,
    s.codigo AS seccion_codigo,
    q.codigo AS pregunta_codigo,
    q.tipo_respuesta,
    o.codigo AS opcion_codigo,
    o.etiqueta,
    o.valor,
    o.orden,
    o.activo
FROM dbo.RC_PREGUNTA_OPCION o
INNER JOIN dbo.RC_PREGUNTA q
    ON q.id = o.pregunta_id
INNER JOIN dbo.RC_SECCION s
    ON s.id = q.seccion_id
WHERE s.formulario_id = @FormularioId
ORDER BY s.orden, q.orden, o.orden;
