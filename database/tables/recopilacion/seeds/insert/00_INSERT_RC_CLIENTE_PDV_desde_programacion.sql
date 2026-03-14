-- =============================================
-- INSERT: RC_CLIENTE_PDV desde PDV_VISITAS_AD_PROGRAMACION
-- Una fila por nro_documento (sin duplicados). Datos para pruebas.
-- =============================================

INSERT INTO dbo.RC_CLIENTE_PDV (nro_documento, nombre_pdv, zonal)
SELECT
    doc AS nro_documento,
    nombre_pdv,
    zonal
FROM (
    SELECT
        RTRIM(COALESCE(NULLIF(RTRIM(p.CEDULA_CLIENTE), ''), NULLIF(RTRIM(p.COD_CLIENTE), ''), CAST(p.DNI_RESPONSABLE AS VARCHAR(20)))) AS doc,
        RTRIM(ISNULL(p.NOMBRE_PUNTO, 'Sin nombre')) AS nombre_pdv,
        RTRIM(ISNULL(p.ZONAL, 'Sin zonal')) AS zonal,
        ROW_NUMBER() OVER (
            PARTITION BY COALESCE(NULLIF(RTRIM(p.CEDULA_CLIENTE), ''), NULLIF(RTRIM(p.COD_CLIENTE), ''), CAST(p.DNI_RESPONSABLE AS VARCHAR(20)))
            ORDER BY p.AÑO DESC, p.MES DESC, p.id
        ) AS rn
    FROM dbo.PDV_VISITAS_AD_PROGRAMACION p
    WHERE COALESCE(NULLIF(RTRIM(p.CEDULA_CLIENTE), ''), NULLIF(RTRIM(p.COD_CLIENTE), ''), CAST(p.DNI_RESPONSABLE AS VARCHAR(20))) IS NOT NULL
      AND RTRIM(ISNULL(p.NOMBRE_PUNTO, '')) <> ''
      AND RTRIM(ISNULL(p.ZONAL, '')) <> ''
) t
WHERE t.rn = 1;
