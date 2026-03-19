DECLARE @FechaInicio DATE = '2026-03-01';  -- ajusta
DECLARE @FechaFin    DATE = '2026-03-31'; -- ajusta
DECLARE @ProdLinea   VARCHAR(30) = NULL;  -- NULL o '' = EQUIPOS (como el SP)

;WITH MaestroUnico AS (
    SELECT
        REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"') AS CNOM_PROD_NORM,
        MARCA,
        MODELO,
        ROW_NUMBER() OVER (
            PARTITION BY REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"')
            ORDER BY MARCA, MODELO
        ) AS rn
    FROM DISTRIBUTOR_DATAMART.dbo.DCN_MAESTRO_PRODUCTO
)
-- JSMS (rama WOLAP)
SELECT
    'JSMS' AS FUENTE,
    v.NRODOC,
    CAST(v.FEC_EMISION AS DATE) AS FEC_EMISION,
    REPLACE(LTRIM(RTRIM(v.NOM_PRODUCTO)), '&quot;', '"') AS NOM_PRODUCTO_NORM,
    p.MARCA,
    p.MODELO
FROM DISTRIBUTOR_DATAMART.dbo.DD_WOLAP_VENTA_ANALISIS_DETALLADO v
LEFT JOIN MaestroUnico p
    ON REPLACE(RTRIM(LTRIM(v.NOM_PRODUCTO)), '&quot;', '"') = p.CNOM_PROD_NORM
    AND p.rn = 1
WHERE CAST(v.FEC_EMISION AS DATE) >= @FechaInicio
  AND CAST(v.FEC_EMISION AS DATE) <= @FechaFin
  AND UPPER(LTRIM(RTRIM(v.ALMACEN))) <> 'AMAZONIA'
  AND LTRIM(RTRIM(v.PROD_LINEA)) <> 'CHIPS'
  AND LTRIM(RTRIM(v.PROD_LINEA)) = COALESCE(NULLIF(LTRIM(RTRIM(@ProdLinea)), ''), 'EQUIPOS')
  AND (
        p.MARCA IS NULL OR LTRIM(RTRIM(p.MARCA)) = ''
      )
  AND (
        p.MODELO IS NULL OR LTRIM(RTRIM(p.MODELO)) = ''
      )

UNION ALL

-- YALI
SELECT
    'AMAZONÍA' AS FUENTE,
    y.Num_Documento,
    CAST(y.Fecha AS DATE),
    REPLACE(LTRIM(RTRIM(y.Descripcion)), '&quot;', '"'),
    p.MARCA,
    p.MODELO
FROM DISTRIBUTOR_DATAMART.dbo.YALI_VENTAS y
LEFT JOIN (
    SELECT CNOM_PROD_NORM, MARCA, MODELO
    FROM (
        SELECT
            REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"') AS CNOM_PROD_NORM,
            MARCA,
            MODELO,
            ROW_NUMBER() OVER (
                PARTITION BY REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"')
                ORDER BY MARCA, MODELO
            ) AS rn
        FROM DISTRIBUTOR_DATAMART.dbo.DCN_MAESTRO_PRODUCTO
    ) m
    WHERE m.rn = 1
) p ON REPLACE(RTRIM(LTRIM(y.Descripcion)), '&quot;', '"') = p.CNOM_PROD_NORM
WHERE CAST(y.Fecha AS DATE) >= @FechaInicio
  AND CAST(y.Fecha AS DATE) <= @FechaFin
  AND (@ProdLinea IS NULL OR LTRIM(RTRIM(@ProdLinea)) = '' OR LTRIM(RTRIM(@ProdLinea)) = 'EQUIPOS')
  AND (
        p.MARCA IS NULL OR LTRIM(RTRIM(p.MARCA)) = ''
      )
  AND (
        p.MODELO IS NULL OR LTRIM(RTRIM(p.MODELO)) = ''
      )
ORDER BY FUENTE, FEC_EMISION, NRODOC;
