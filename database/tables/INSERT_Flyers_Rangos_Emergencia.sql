-- =============================================
-- INSERT DE EMERGENCIA: Flyers por RANGO
-- Fecha: Diciembre 2025
-- Descripción: Inserta flyers directamente en PDV_OUT_FLYERS
-- basándose en el campo RANGO de PDV_OUT_ENTREGABLE
--
-- IMPORTANTE: Este script inserta en DOS tablas:
-- 1. PDV_OUT_CAMPAÑAS_FLYERS (para que aparezcan en /campañas)
-- 2. PDV_OUT_FLYERS (asignaciones a responsables)
-- =============================================

-- =============================================
-- PRIMERO: Insertar las CAMPAÑAS en PDV_OUT_CAMPAÑAS_FLYERS
-- Esto es necesario para que aparezcan en la ruta /campañas
-- =============================================

-- Campaña 1: RANGO 1-2
INSERT INTO PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS (
    nombre_campaña,
    foto_esquema,
    fecha_inicio,
    fecha_fin,
    tipoImg,
    modo,
    criterio_filtro,
    zonales,
    activa,
    todos,
    comunicado,
    archivo_comunicacion,
    fecha_comunicacion
)
VALUES (
    'Acelerador_PDVRegular_ 05-9Diciembre1-2.jpg',
    'Acelerador_PDVRegular_ 05-9Diciembre1-2.jpg',
    '2025-12-05',
    '2025-12-09',
    'ACELERADOR',
    'PDV',
    'RANGO 1-2',  -- Criterio de filtro por RANGO
    NULL,  -- Todas las zonales
    1,  -- Activa
    0,  -- No es "todos", tiene criterio específico
    0,  -- No comunicado
    NULL,
    NULL
);

-- Campaña 2: RANGO 3-4
INSERT INTO PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS (
    nombre_campaña,
    foto_esquema,
    fecha_inicio,
    fecha_fin,
    tipoImg,
    modo,
    criterio_filtro,
    zonales,
    activa,
    todos,
    comunicado,
    archivo_comunicacion,
    fecha_comunicacion
)
VALUES (
    'Acelerador_PDVRegular_ 05-9Diciembre_3-4.jpg',
    'Acelerador_PDVRegular_ 05-9Diciembre_3-4.jpg',
    '2025-12-05',
    '2025-12-09',
    'ACELERADOR',
    'PDV',
    'RANGO 3-4',  -- Criterio de filtro por RANGO
    NULL,  -- Todas las zonales
    1,  -- Activa
    0,  -- No es "todos", tiene criterio específico
    0,  -- No comunicado
    NULL,
    NULL
);

-- Campaña 3: RANGO 5-8
INSERT INTO PORTAL_COMERCIAL.dbo.PDV_OUT_CAMPAÑAS_FLYERS (
    nombre_campaña,
    foto_esquema,
    fecha_inicio,
    fecha_fin,
    tipoImg,
    modo,
    criterio_filtro,
    zonales,
    activa,
    todos,
    comunicado,
    archivo_comunicacion,
    fecha_comunicacion
)
VALUES (
    'Acelerador_PDVRegular_ 05-9Diciembre_5-8.jpg',
    'Acelerador_PDVRegular_ 05-9Diciembre_5-8.jpg',
    '2025-12-05',
    '2025-12-09',
    'ACELERADOR',
    'PDV',
    'RANGO 5-8',  -- Criterio de filtro por RANGO
    NULL,  -- Todas las zonales
    1,  -- Activa
    0,  -- No es "todos", tiene criterio específico
    0,  -- No comunicado
    NULL,
    NULL
);

-- =============================================
-- SEGUNDO: Insertar las ASIGNACIONES en PDV_OUT_FLYERS
-- Esto asigna los flyers a cada responsable según su RANGO
-- =============================================

-- =============================================
-- SENTENCIA 1: RANGO 1 y RANGO 2
-- Imagen: Acelerador_PDVRegular_ 05-9Diciembre1-2.jpg
-- =============================================
INSERT INTO PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS (
    año,
    mes,
    dni_responsable,
    zonal,
    foto_esquema,
    fecha_inicio,
    fecha_fin,
    tipoImg
)
SELECT DISTINCT
    2025 AS año,
    12 AS mes,
    CAST(e.DNI_RESPONSABLE AS VARCHAR(50)) AS dni_responsable,
    e.ZONAL,
    'Acelerador_PDVRegular_ 05-9Diciembre1-2.jpg' AS foto_esquema,
    '2025-12-05' AS fecha_inicio,
    '2025-12-09' AS fecha_fin,
    NULL AS tipoImg
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e
WHERE
    e.AÑO = 2025
    AND e.MES = 12
    AND (e.RANGO = 'RANGO 1' OR e.RANGO = 'RANGO 2')
    AND e.DNI_RESPONSABLE IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
        WHERE f.dni_responsable = CAST(e.DNI_RESPONSABLE AS VARCHAR(50))
        AND f.foto_esquema = 'Acelerador_PDVRegular_ 05-9Diciembre1-2.jpg'
        AND f.fecha_inicio = '2025-12-05'
        AND f.fecha_fin = '2025-12-09'
    );

-- =============================================
-- SENTENCIA 2: RANGO 3 y RANGO 4
-- Imagen: Acelerador_PDVRegular_ 05-9Diciembre_3-4.jpg
-- =============================================
INSERT INTO PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS (
    año,
    mes,
    dni_responsable,
    zonal,
    foto_esquema,
    fecha_inicio,
    fecha_fin,
    tipoImg
)
SELECT DISTINCT
    2025 AS año,
    12 AS mes,
    CAST(e.DNI_RESPONSABLE AS VARCHAR(50)) AS dni_responsable,
    e.ZONAL,
    'Acelerador_PDVRegular_ 05-9Diciembre_3-4.jpg' AS foto_esquema,
    '2025-12-05' AS fecha_inicio,
    '2025-12-09' AS fecha_fin,
    NULL AS tipoImg
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e
WHERE
    e.AÑO = 2025
    AND e.MES = 12
    AND (e.RANGO = 'RANGO 3' OR e.RANGO = 'RANGO 4')
    AND e.DNI_RESPONSABLE IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
        WHERE f.dni_responsable = CAST(e.DNI_RESPONSABLE AS VARCHAR(50))
        AND f.foto_esquema = 'Acelerador_PDVRegular_ 05-9Diciembre_3-4.jpg'
        AND f.fecha_inicio = '2025-12-05'
        AND f.fecha_fin = '2025-12-09'
    );

-- =============================================
-- SENTENCIA 3: RANGO 5, 6, 7 y 8
-- Imagen: Acelerador_PDVRegular_ 05-9Diciembre_5-8.jpg
-- =============================================
INSERT INTO PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS (
    año,
    mes,
    dni_responsable,
    zonal,
    foto_esquema,
    fecha_inicio,
    fecha_fin,
    tipoImg
)
SELECT DISTINCT
    2025 AS año,
    12 AS mes,
    CAST(e.DNI_RESPONSABLE AS VARCHAR(50)) AS dni_responsable,
    e.ZONAL,
    'Acelerador_PDVRegular_ 05-9Diciembre_5-8.jpg' AS foto_esquema,
    '2025-12-05' AS fecha_inicio,
    '2025-12-09' AS fecha_fin,
    NULL AS tipoImg
FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e
WHERE
    e.AÑO = 2025
    AND e.MES = 12
    AND (e.RANGO = 'RANGO 5' OR e.RANGO = 'RANGO 6' OR e.RANGO = 'RANGO 7' OR e.RANGO = 'RANGO 8')
    AND e.DNI_RESPONSABLE IS NOT NULL
    AND NOT EXISTS (
        SELECT 1
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FLYERS f
        WHERE f.dni_responsable = CAST(e.DNI_RESPONSABLE AS VARCHAR(50))
        AND f.foto_esquema = 'Acelerador_PDVRegular_ 05-9Diciembre_5-8.jpg'
        AND f.fecha_inicio = '2025-12-05'
        AND f.fecha_fin = '2025-12-09'
    );

