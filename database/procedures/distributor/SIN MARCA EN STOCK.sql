DECLARE @linea   VARCHAR(50)  = 'EQUIPOS';  -- NULL o '' = todas las líneas (como el SP)
DECLARE @almacen VARCHAR(100) = NULL;  -- NULL o '' = lista de almacenes JS + todos YALI mapeados

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
),
SinMarca AS (
    /* JS — WOLAP_CONSULTA_SERIES (mismo linked server y join que sp_Stock_General) */
    SELECT REPLACE(RTRIM(LTRIM(w.CNOM_PROD)), '&quot;', '"') AS CNOM_PROD_NORM
    FROM [192.168.3.101,1800\MSSQL_NEW].[Distribuidora].[dbo].[WOLAP_CONSULTA_SERIES] w
    LEFT JOIN MaestroUnico p
        ON REPLACE(RTRIM(LTRIM(w.CNOM_PROD)), '&quot;', '"') = p.CNOM_PROD_NORM
        AND p.rn = 1
    WHERE (@linea IS NULL OR RTRIM(LTRIM(@linea)) = ''
        OR LOWER(RTRIM(LTRIM(w.LINEA))) = LOWER(RTRIM(LTRIM(@linea))))
      AND (
            (@almacen IS NULL OR RTRIM(LTRIM(@almacen)) = '')
            AND (
                UPPER(LTRIM(RTRIM(w.ALMACEN))) IN (
                    'AREQUIPA', 'AYACUCHO', 'CUSCO', 'E-COMMERCE', 'HUANCAYO', 'HUANUCO', 'HUÁNUCO',
                    'ICA', 'LA MERCED', 'LIMA SUR', 'PUCALLPA', 'PUNO'
                )
                OR UPPER(LTRIM(RTRIM(w.ALMACEN))) COLLATE Latin1_General_CI_AI = 'HUANUCO'
            )
            OR (
                @almacen IS NOT NULL AND RTRIM(LTRIM(@almacen)) <> ''
                AND UPPER(LTRIM(RTRIM(w.ALMACEN))) COLLATE Latin1_General_CI_AI
                    = UPPER(LTRIM(RTRIM(@almacen))) COLLATE Latin1_General_CI_AI
            )
        )
      AND (p.MARCA IS NULL OR LTRIM(RTRIM(p.MARCA)) = '')
      AND (p.MODELO IS NULL OR LTRIM(RTRIM(p.MODELO)) = '')

    UNION ALL

    /* YALI — YALI_STOCK: el join al maestro usa y.Modelo (no Descripción) */
    SELECT REPLACE(RTRIM(LTRIM(y.Modelo)), '&quot;', '"')
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
        ) x
        WHERE x.rn = 1
    ) m ON REPLACE(RTRIM(LTRIM(y.Modelo)), '&quot;', '"') = m.CNOM_PROD_NORM
    WHERE (
        @linea IS NULL
        OR RTRIM(LTRIM(@linea)) = ''
        OR LOWER(RTRIM(LTRIM(ISNULL(@linea, '')))) = 'equipos'
        OR LOWER(RTRIM(LTRIM(ISNULL(y.Tipo, '')))) = LOWER(RTRIM(LTRIM(@linea)))
    )
      AND (
        @almacen IS NULL OR RTRIM(LTRIM(@almacen)) = ''
        OR (
            CASE
                WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) = 'UCAYALI' THEN 'PUCALLPA'
                WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) COLLATE Latin1_General_CI_AI = 'HUANUCO' THEN 'HUANUCO'
                WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) = 'PICHANAQUI' THEN 'LA MERCED'
                WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) = 'PICHARI' THEN 'AYACUCHO'
                WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) = 'QUILLABAMBA' THEN 'CUSCO'
                ELSE UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', '')))))
            END
            = CASE
                WHEN UPPER(LTRIM(RTRIM(@almacen))) = 'UCAYALI' THEN 'PUCALLPA'
                WHEN UPPER(LTRIM(RTRIM(@almacen))) COLLATE Latin1_General_CI_AI = 'HUANUCO' THEN 'HUANUCO'
                WHEN UPPER(LTRIM(RTRIM(@almacen))) = 'PICHANAQUI' THEN 'LA MERCED'
                WHEN UPPER(LTRIM(RTRIM(@almacen))) = 'PICHARI' THEN 'AYACUCHO'
                WHEN UPPER(LTRIM(RTRIM(@almacen))) = 'QUILLABAMBA' THEN 'CUSCO'
                ELSE UPPER(LTRIM(RTRIM(@almacen)))
              END
        )
      )
      AND (m.MARCA IS NULL OR LTRIM(RTRIM(m.MARCA)) = '')
      AND (m.MODELO IS NULL OR LTRIM(RTRIM(m.MODELO)) = '')
)
SELECT DISTINCT CNOM_PROD_NORM
FROM SinMarca
WHERE CNOM_PROD_NORM IS NOT NULL
  AND LTRIM(RTRIM(CNOM_PROD_NORM)) <> ''
ORDER BY CNOM_PROD_NORM;
