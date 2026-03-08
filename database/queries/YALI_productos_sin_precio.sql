-- Productos YALI que NO hacen match con precios (linked 1900).
-- Misma base y filtros que sp_Stock_General (@linea='EQUIPOS', @almacen opcional) y mismo match que sp_Resumen_Stock.
-- @almacen = NULL para todos los almacenes; o ej. 'PICHANAQUI' para filtrar por zonal.
DECLARE @linea   VARCHAR(50)  = 'EQUIPOS';
DECLARE @almacen VARCHAR(100) = NULL;

;WITH MaestroUnico AS (
    SELECT
        REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"') AS CNOM_PROD_NORM,
        MARCA,
        MODELO,
        ROW_NUMBER() OVER (PARTITION BY REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"') ORDER BY MARCA, MODELO) AS rn
    FROM DISTRIBUTOR_DATAMART.dbo.DCN_MAESTRO_PRODUCTO
),
BaseYali AS (
    SELECT
        RTRIM(LTRIM(y.Modelo)) AS CNOM_PROD,
        CAST(y.Codigo AS VARCHAR(50)) AS CCOD_PROD,
        RTRIM(LTRIM(m.MARCA)) AS MARCA,
        RTRIM(LTRIM(m.MODELO)) AS MODELO
    FROM DISTRIBUTOR_DATAMART.dbo.YALI_STOCK y
    LEFT JOIN (
        SELECT CSERIE, ALMACEN
        FROM (
            SELECT CSERIE, ALMACEN,
                ROW_NUMBER() OVER (PARTITION BY CSERIE ORDER BY (SELECT NULL)) AS rn
            FROM DISTRIBUTOR_DATAMART.dbo.YALI_SERIES_TRASLADOS
        ) t0
        WHERE t0.rn = 1
    ) t ON y.IMEI = t.CSERIE
    LEFT JOIN MaestroUnico m ON REPLACE(RTRIM(LTRIM(y.Modelo)), '&quot;', '"') = m.CNOM_PROD_NORM AND m.rn = 1
    WHERE (
        @linea IS NULL
        OR RTRIM(LTRIM(@linea)) = ''
        OR LOWER(RTRIM(LTRIM(ISNULL(@linea, '')))) = 'equipos'
        OR LOWER(RTRIM(LTRIM(ISNULL(y.Tipo, '')))) = LOWER(RTRIM(LTRIM(@linea)))
    )
    AND (
        @almacen IS NULL OR RTRIM(LTRIM(@almacen)) = ''
        OR (
            CASE WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) = 'UCAYALI' THEN 'PUCALLPA'
                 WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) COLLATE Latin1_General_CI_AI = 'HUANUCO' THEN 'HUANUCO'
                 ELSE UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', '')))))
            END
            = CASE WHEN UPPER(LTRIM(RTRIM(@almacen))) = 'UCAYALI' THEN 'PUCALLPA'
                   WHEN UPPER(LTRIM(RTRIM(@almacen))) COLLATE Latin1_General_CI_AI = 'HUANUCO' THEN 'HUANUCO'
                   ELSE UPPER(LTRIM(RTRIM(@almacen)))
              END
        )
    )
),
PreciosYali AS (
    SELECT
        RTRIM(LTRIM(REPLACE(ISNULL(d.CNOM_PROD, ''), '&quot;', '"'))) AS CNOM_PROD,
        d.PRECIO
    FROM [192.168.3.101,1900\MSSQL_log].[Distribuidora].[dbo].[WOLAP_PRECIOS_DETALLISTA] d
),
ConPrecio AS (
    SELECT
        b.CNOM_PROD,
        b.CCOD_PROD,
        b.MARCA,
        b.MODELO,
        COALESCE(p1.PRECIO, p2.PRECIO) AS PRECIO_VTA
    FROM (SELECT DISTINCT CNOM_PROD, CCOD_PROD, MARCA, MODELO FROM BaseYali) b
    OUTER APPLY (
        SELECT MAX(p.PRECIO) AS PRECIO
        FROM PreciosYali p
        WHERE LEN(RTRIM(LTRIM(REPLACE(ISNULL(b.CNOM_PROD, ''), '&quot;', '"')))) > 0
          AND RTRIM(LTRIM(p.CNOM_PROD)) COLLATE Latin1_General_CI_AI
              LIKE RTRIM(LTRIM(REPLACE(ISNULL(b.CNOM_PROD, ''), '&quot;', '"'))) COLLATE Latin1_General_CI_AI + '%'
    ) p1
    OUTER APPLY (
        SELECT MAX(p.PRECIO) AS PRECIO
        FROM PreciosYali p
        WHERE LEN(RTRIM(LTRIM(ISNULL(b.MODELO, '')))) > 0
          AND RTRIM(LTRIM(p.CNOM_PROD)) COLLATE Latin1_General_CI_AI
              LIKE RTRIM(LTRIM(ISNULL(b.MODELO, ''))) COLLATE Latin1_General_CI_AI + '%'
    ) p2
)
SELECT CNOM_PROD, CCOD_PROD, MARCA, MODELO
FROM ConPrecio
WHERE PRECIO_VTA IS NULL
ORDER BY CNOM_PROD;
