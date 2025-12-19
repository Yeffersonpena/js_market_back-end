-- =============================================
-- INSERT ALTERNATIVO: Campañas Flyers por RANGO
-- Versión con formato de fecha explícito usando CAST
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
    CAST('2025-12-05' AS DATE),
    CAST('2025-12-09' AS DATE),
    'ACELERADOR',
    'PDV',
    'RANGO 1-2',
    NULL,
    1,
    0,
    0,
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
    CAST('2025-12-05' AS DATE),
    CAST('2025-12-09' AS DATE),
    'ACELERADOR',
    'PDV',
    'RANGO 3-4',
    NULL,
    1,
    0,
    0,
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
    CAST('2025-12-05' AS DATE),
    CAST('2025-12-09' AS DATE),
    'ACELERADOR',
    'PDV',
    'RANGO 5-8',
    NULL,
    1,
    0,
    0,
    NULL,
    NULL
);

