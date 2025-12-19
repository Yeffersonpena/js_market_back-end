-- =============================================
-- QUERIES DE VERIFICACIÓN: Campañas Flyers
-- Usa estas queries para verificar qué está pasando
-- =============================================

-- 0. Verificar la conexión y esquema correcto
SELECT
    DB_NAME() AS base_datos_actual,
    SCHEMA_NAME() AS esquema_actual;

-- Verificar si la tabla existe
SELECT
    TABLE_SCHEMA,
    TABLE_NAME
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_NAME = 'PDV_OUT_CAMPAÑAS_FLYERS';

-- 1. Verificar si existen las campañas en PDV_OUT_CAMPAÑAS_FLYERS
SELECT
    id,
    nombre_campaña,
    foto_esquema,
    fecha_inicio,
    fecha_fin,
    YEAR(fecha_inicio) AS año_inicio,
    MONTH(fecha_inicio) AS mes_inicio,
    tipoImg,
    modo,
    criterio_filtro,
    activa,
    todos
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS
WHERE foto_esquema LIKE '%Diciembre%'
ORDER BY fecha_inicio DESC;

-- 2. Verificar campañas específicas para año 2025 y mes 12
SELECT
    id,
    nombre_campaña,
    foto_esquema,
    fecha_inicio,
    fecha_fin,
    YEAR(fecha_inicio) AS año_inicio,
    MONTH(fecha_inicio) AS mes_inicio,
    tipoImg,
    modo,
    criterio_filtro,
    activa
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS
WHERE YEAR(fecha_inicio) = 2025
  AND MONTH(fecha_inicio) = 12
ORDER BY fecha_inicio DESC;

-- 3. Verificar todas las campañas recientes
SELECT TOP 10
    id,
    nombre_campaña,
    foto_esquema,
    fecha_inicio,
    fecha_fin,
    YEAR(fecha_inicio) AS año_inicio,
    MONTH(fecha_inicio) AS mes_inicio,
    tipoImg,
    modo,
    activa,
    fecha_creacion
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS
ORDER BY fecha_creacion DESC;

-- 4. Verificar si hay registros en PDV_OUT_FLYERS (las asignaciones)
SELECT
    COUNT(*) AS total_registros,
    foto_esquema,
    MIN(fecha_inicio) AS fecha_inicio_min,
    MAX(fecha_inicio) AS fecha_inicio_max
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS
WHERE foto_esquema LIKE '%Diciembre%'
GROUP BY foto_esquema;

-- 5. Verificar registros específicos por imagen
SELECT
    COUNT(*) AS total,
    foto_esquema,
    año,
    mes
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS
WHERE foto_esquema IN (
    'Acelerador_PDVRegular_ 05-9Diciembre1-2.jpg',
    'Acelerador_PDVRegular_ 05-9Diciembre_3-4.jpg',
    'Acelerador_PDVRegular_ 05-9Diciembre_5-8.jpg'
)
GROUP BY foto_esquema, año, mes;

