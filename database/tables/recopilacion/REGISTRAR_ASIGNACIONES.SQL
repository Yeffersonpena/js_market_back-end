INSERT INTO PORTAL_COMERCIAL.dbo.RC_PDV_ASIGNACION_VISITA (
    pdv_id,
    zonal,
    nombre_jefe_ejecutivo,
    fecha_visita_tentativa,
    monto_viatico,
    comentario,
    dni_ejecutor
)
SELECT
    c.id AS pdv_id,
    s.zonal,
    COALESCE(NULLIF(LTRIM(RTRIM(m.nombre_correcto)), ''), s.nombre_jefe_ejecutivo) AS nombre_jefe_ejecutivo,
    CASE
        WHEN s.fecha_visita_raw IS NULL THEN NULL
        WHEN LTRIM(RTRIM(s.fecha_visita_raw)) IN ('', '-') THEN NULL
        WHEN TRY_CONVERT(DATE, s.fecha_visita_raw, 103) IS NOT NULL
            THEN TRY_CONVERT(DATE, s.fecha_visita_raw, 103)
        WHEN TRY_CONVERT(FLOAT, REPLACE(s.fecha_visita_raw, ',', '.')) BETWEEN 1 AND 80000
            THEN DATEADD(
                    DAY,
                    CONVERT(INT, TRY_CONVERT(FLOAT, REPLACE(s.fecha_visita_raw, ',', '.'))),
                    DATEFROMPARTS(1899, 12, 30)
                 )
        ELSE NULL
    END AS fecha_visita_tentativa,
    CASE
        WHEN s.monto_viatico_raw IS NULL THEN NULL
        WHEN LTRIM(RTRIM(s.monto_viatico_raw)) IN ('', '-', 'S/ -') THEN NULL
        WHEN TRY_CONVERT(DECIMAL(10,2), s.monto_viatico_raw) IS NOT NULL
            THEN TRY_CONVERT(DECIMAL(10,2), s.monto_viatico_raw)
        ELSE TRY_CONVERT(
                DECIMAL(10,2),
                REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(s.monto_viatico_raw)), 'S/', ''), ' ', ''), ',', '.')
             )
    END AS monto_viatico,
    NULLIF(LTRIM(RTRIM(s.comentario)), '') AS comentario,
    CASE
        WHEN UPPER(LTRIM(RTRIM(REPLACE(s.cargo, CHAR(160), ' ')))) LIKE 'JEFE%'
            THEN j.dni_jefe_zonal
        WHEN UPPER(LTRIM(RTRIM(REPLACE(s.cargo, CHAR(160), ' ')))) LIKE 'VENDEDOR%'
            THEN v.dni_vendedor
        ELSE NULL
    END AS dni_ejecutor
FROM PORTAL_COMERCIAL.dbo.RC_PDV_ASIGNACION_VISITA_STG s
INNER JOIN PORTAL_COMERCIAL.dbo.RC_CLIENTE_PDV c
    ON LTRIM(RTRIM(c.nro_documento)) = LTRIM(RTRIM(s.dni_responsable))
LEFT JOIN PORTAL_COMERCIAL.dbo.RC_EJECUTOR_NOMBRE_MAP m
    ON UPPER(LTRIM(RTRIM(REPLACE(s.cargo, CHAR(160), ' ')))) =
       UPPER(LTRIM(RTRIM(REPLACE(m.cargo, CHAR(160), ' '))))
   AND UPPER(LTRIM(RTRIM(REPLACE(s.nombre_jefe_ejecutivo, CHAR(160), ' ')))) =
       UPPER(LTRIM(RTRIM(REPLACE(m.nombre_excel, CHAR(160), ' '))))
LEFT JOIN dbo.PDV_JEFE_ZONAL j
    ON UPPER(LTRIM(RTRIM(COALESCE(m.nombre_correcto, s.nombre_jefe_ejecutivo)))) COLLATE Modern_Spanish_CI_AI =
       UPPER(LTRIM(RTRIM(j.nombre_jefe_zonal))) COLLATE Modern_Spanish_CI_AI
LEFT JOIN dbo.PDV_VENDEDORES v
    ON UPPER(LTRIM(RTRIM(COALESCE(m.nombre_correcto, s.nombre_jefe_ejecutivo)))) COLLATE Modern_Spanish_CI_AI =
       UPPER(LTRIM(RTRIM(v.nombre_vendedor))) COLLATE Modern_Spanish_CI_AI
WHERE NOT EXISTS (
    SELECT 1
    FROM PORTAL_COMERCIAL.dbo.RC_PDV_ASIGNACION_VISITA t
    WHERE t.pdv_id = c.id
      AND t.nombre_jefe_ejecutivo = COALESCE(NULLIF(LTRIM(RTRIM(m.nombre_correcto)), ''), s.nombre_jefe_ejecutivo)
      AND ISNULL(t.fecha_visita_tentativa, '19000101') = ISNULL(
            CASE
                WHEN s.fecha_visita_raw IS NULL THEN NULL
                WHEN LTRIM(RTRIM(s.fecha_visita_raw)) IN ('', '-') THEN NULL
                WHEN TRY_CONVERT(DATE, s.fecha_visita_raw, 103) IS NOT NULL
                    THEN TRY_CONVERT(DATE, s.fecha_visita_raw, 103)
                WHEN TRY_CONVERT(FLOAT, REPLACE(s.fecha_visita_raw, ',', '.')) BETWEEN 1 AND 80000
                    THEN DATEADD(
                            DAY,
                            CONVERT(INT, TRY_CONVERT(FLOAT, REPLACE(s.fecha_visita_raw, ',', '.'))),
                            DATEFROMPARTS(1899, 12, 30)
                         )
                ELSE NULL
            END, '19000101'
      )
);
