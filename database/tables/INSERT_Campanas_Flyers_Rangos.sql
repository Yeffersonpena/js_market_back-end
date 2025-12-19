-- =============================================
-- INSERT DE EMERGENCIA: Campañas Flyers por RANGO
-- Fecha: Diciembre 2025
-- Descripción: Inserta las CAMPAÑAS en PDV_OUT_CAMPAÑAS_FLYERS
-- para que aparezcan en la ruta /campañas
--
-- NOTA: Las asignaciones en PDV_OUT_FLYERS ya fueron ejecutadas
-- Este script solo crea las campañas para que se visualicen
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

