-- Stock por serie desde WOLAP_CONSULTA_SERIES (linked server) + YALI_STOCK.
-- Campos unificados; MARCA/MODELO por join a DCN_MAESTRO_PRODUCTO (CTE evita duplicados).
-- YALI: ALMACEN desde YALI_SERIES_TRASLADOS si existe, sino NombrePV sin prefijo 'YALI-'.
--
CREATE PROCEDURE sp_Stock_General
    @linea VARCHAR(50) = NULL,
    @almacen VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH MaestroUnico AS (
        SELECT
            REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"') AS CNOM_PROD_NORM,
            MARCA,
            MODELO,
            ROW_NUMBER() OVER (PARTITION BY REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"') ORDER BY MARCA, MODELO) AS rn
        FROM DISTRIBUTOR_DATAMART.dbo.DCN_MAESTRO_PRODUCTO
    )
    SELECT
        RTRIM(LTRIM(@linea)) AS TIPO,
        RTRIM(LTRIM(w.CSERIE)) AS CSERIE,
        RTRIM(LTRIM(w.PROVEEDOR)) AS PROVEEDOR,
        CAST(w.FCOMPRA AS DATE) AS FCOMPRA,
        DATEDIFF(day, w.FCOMPRA, GETDATE()) AS DIAS,
        CASE
            WHEN w.FCOMPRA IS NULL THEN '-'
            WHEN DATEDIFF(day, w.FCOMPRA, GETDATE()) BETWEEN 0 AND 15 THEN '0 - 15'
            WHEN DATEDIFF(day, w.FCOMPRA, GETDATE()) > 15 AND DATEDIFF(day, w.FCOMPRA, GETDATE()) <= 30 THEN '15 - 30'
            WHEN DATEDIFF(day, w.FCOMPRA, GETDATE()) > 30 AND DATEDIFF(day, w.FCOMPRA, GETDATE()) <= 70 THEN '30 - 70'
            WHEN DATEDIFF(day, w.FCOMPRA, GETDATE()) > 70 AND DATEDIFF(day, w.FCOMPRA, GETDATE()) <= 90 THEN '70 - 90'
            ELSE '> 90'
        END AS EDAD,
        w.NCOSTO AS NCOSTO,
        CAST(w.NCOSTO * 1.18 AS DECIMAL(18,4)) AS COSTO,
        RTRIM(LTRIM(w.CNOM_PROD)) AS CNOM_PROD,
        RTRIM(LTRIM(CAST(w.CCOD_PROD AS VARCHAR(50)))) AS CCOD_PROD,
        RTRIM(LTRIM(p.MARCA)) AS MARCA,
        RTRIM(LTRIM(p.MODELO)) AS MODELO,
        RTRIM(LTRIM(w.LINEA)) AS LINEA,
        RTRIM(LTRIM(w.SUBLINEA)) AS SUBLINEA,
        CASE WHEN UPPER(LTRIM(RTRIM(w.ALMACEN))) COLLATE Latin1_General_CI_AI = 'HUANUCO' THEN 'HUANUCO' ELSE UPPER(LTRIM(RTRIM(w.ALMACEN))) END AS ALMACEN,
        'JS' AS EMPRESA
    FROM [192.168.3.101,1800\MSSQL_NEW].[Distribuidora].[dbo].[WOLAP_CONSULTA_SERIES] w
    LEFT JOIN MaestroUnico p
        ON REPLACE(RTRIM(LTRIM(w.CNOM_PROD)), '&quot;', '"') = p.CNOM_PROD_NORM
        AND p.rn = 1
    WHERE (@linea IS NULL OR RTRIM(LTRIM(@linea)) = '' OR LOWER(RTRIM(LTRIM(w.LINEA))) = LOWER(RTRIM(LTRIM(@linea))))
        AND (
            (
                @almacen IS NULL OR RTRIM(LTRIM(@almacen)) = ''
            )
            AND ( UPPER(LTRIM(RTRIM(w.ALMACEN))) IN (
                'AREQUIPA', 'AYACUCHO', 'CUSCO', 'E-COMMERCE', 'HUANCAYO', 'HUANUCO', 'HUÁNUCO',
                'ICA', 'LA MERCED', 'LIMA SUR', 'PUCALLPA', 'PUNO'
            ) OR UPPER(LTRIM(RTRIM(w.ALMACEN))) COLLATE Latin1_General_CI_AI = 'HUANUCO' )
            OR
            (
                @almacen IS NOT NULL AND RTRIM(LTRIM(@almacen)) <> ''
                AND UPPER(LTRIM(RTRIM(w.ALMACEN))) COLLATE Latin1_General_CI_AI = UPPER(LTRIM(RTRIM(@almacen))) COLLATE Latin1_General_CI_AI
            )
        )

    UNION ALL

    -- YALI: FCOMPRA/DIAS/EDAD usan FechaFactura (igual que Power Query Amazonía en database/queries/STOCK_PQ.SQL).
    SELECT
        RTRIM(LTRIM(@linea)) AS TIPO,
        RTRIM(LTRIM(y.IMEI)) AS CSERIE,
        RTRIM(LTRIM(y.Proveedor)) AS PROVEEDOR,
        CAST(y.FechaFactura AS DATE) AS FCOMPRA,
        DATEDIFF(day, y.FechaFactura, GETDATE()) AS DIAS,
        CASE
            WHEN y.FechaFactura IS NULL THEN '-'
            WHEN DATEDIFF(day, y.FechaFactura, GETDATE()) BETWEEN 0 AND 15 THEN '0 - 15'
            WHEN DATEDIFF(day, y.FechaFactura, GETDATE()) > 15 AND DATEDIFF(day, y.FechaFactura, GETDATE()) <= 30 THEN '15 - 30'
            WHEN DATEDIFF(day, y.FechaFactura, GETDATE()) > 30 AND DATEDIFF(day, y.FechaFactura, GETDATE()) <= 70 THEN '30 - 70'
            WHEN DATEDIFF(day, y.FechaFactura, GETDATE()) > 70 AND DATEDIFF(day, y.FechaFactura, GETDATE()) <= 90 THEN '70 - 90'
            ELSE '> 90'
        END AS EDAD,
        COALESCE(y.CosteTotal, y.Precio) AS NCOSTO,
        COALESCE(y.CosteTotal, y.Precio) AS COSTO,
        RTRIM(LTRIM(y.Modelo)) AS CNOM_PROD,
        CAST(y.Codigo AS VARCHAR(50)) AS CCOD_PROD,
        RTRIM(LTRIM(m.MARCA)) AS MARCA,
        RTRIM(LTRIM(m.MODELO)) AS MODELO,
        'EQUIPOS' AS LINEA,
        'EQUIPOS' AS SUBLINEA,
        CASE
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) = 'UCAYALI' THEN 'PUCALLPA'
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) COLLATE Latin1_General_CI_AI = 'HUANUCO' THEN 'HUANUCO'
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) = 'PICHANAQUI' THEN 'LA MERCED'
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) = 'PICHARI' THEN 'AYACUCHO'
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) = 'QUILLABAMBA' THEN 'CUSCO'
            ELSE UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', '')))))
        END AS ALMACEN,
        'AMAZONÍA' AS EMPRESA
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
                ROW_NUMBER() OVER (PARTITION BY REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"') ORDER BY MARCA, MODELO) AS rn
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
        );
END

