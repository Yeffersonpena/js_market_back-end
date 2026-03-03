-- Stock por serie desde WOLAP_CONSULTA_SERIES (linked server) + YALI_STOCK.
-- Campos unificados; MARCA/MODELO por join a DCN_MAESTRO_PRODUCTO (CTE evita duplicados).
-- YALI: ALMACEN desde YALI_SERIES_TRASLADOS si existe, sino NombrePV sin prefijo 'YALI-'.
CREATE PROCEDURE sp_Stock_JS_Yali
    @linea VARCHAR(50) = NULL
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
            WHEN DATEDIFF(day, w.FCOMPRA, GETDATE()) < 15 THEN '< 15'
            WHEN DATEDIFF(day, w.FCOMPRA, GETDATE()) <= 30 THEN '15 - 30'
            WHEN DATEDIFF(day, w.FCOMPRA, GETDATE()) <= 70 THEN '30 - 70'
            WHEN DATEDIFF(day, w.FCOMPRA, GETDATE()) <= 90 THEN '70 - 90'
            ELSE '> 90'
        END AS EDAD,
        w.NCOSTO AS NCOSTO,
        CAST(w.NCOSTO * 1.18 AS DECIMAL(18,4)) AS COSTO,
        RTRIM(LTRIM(w.CNOM_PROD)) AS CNOM_PROD,
        RTRIM(LTRIM(p.MARCA)) AS MARCA,
        RTRIM(LTRIM(p.MODELO)) AS MODELO,
        RTRIM(LTRIM(w.LINEA)) AS LINEA,
        RTRIM(LTRIM(w.SUBLINEA)) AS SUBLINEA,
        UPPER(RTRIM(LTRIM(w.ALMACEN))) AS ALMACEN,
        'JS' AS EMPRESA,
        pv.PRECIO AS PRECIO_VTA
    FROM [192.168.3.101,1800\MSSQL_NEW].[Distribuidora].[dbo].[WOLAP_CONSULTA_SERIES] w
    LEFT JOIN MaestroUnico p
        ON REPLACE(RTRIM(LTRIM(w.CNOM_PROD)), '&quot;', '"') = p.CNOM_PROD_NORM
        AND p.rn = 1
    LEFT JOIN (
        SELECT
            RTRIM(LTRIM(CNOM_PROD)) AS CNOM_NORM,
            UPPER(RTRIM(LTRIM(REPLACE(CNOM_TIPOVENTA, 'JSM - ', '')))) AS TIPO_VENTA_NORM,
            MAX(PRECIO) AS PRECIO
        FROM [192.168.3.101,1800\MSSQL_NEW].[Distribuidora].[dbo].[WOLAP_PRECIOS_DETALLISTA]
        GROUP BY RTRIM(LTRIM(CNOM_PROD)), UPPER(RTRIM(LTRIM(REPLACE(CNOM_TIPOVENTA, 'JSM - ', ''))))
    ) pv ON RTRIM(LTRIM(w.CNOM_PROD)) = pv.CNOM_NORM
        AND UPPER(RTRIM(LTRIM(w.ALMACEN))) = pv.TIPO_VENTA_NORM
    WHERE (@linea IS NULL OR RTRIM(LTRIM(@linea)) = '' OR LOWER(RTRIM(LTRIM(w.LINEA))) = LOWER(RTRIM(LTRIM(@linea))))
        AND UPPER(RTRIM(LTRIM(w.ALMACEN))) IN (
            'AREQUIPA', 'AYACUCHO', 'CUSCO',  'HUANCAYO', 'HUÁNUCO',
            'ICA', 'LA MERCED', 'LIMA SUR', 'PUCALLPA', 'PUNO'
        )
        --'E-COMMERCE',

    UNION ALL

    SELECT
        RTRIM(LTRIM(@linea)) AS TIPO,
        RTRIM(LTRIM(y.IMEI)) AS CSERIE,
        RTRIM(LTRIM(y.Proveedor)) AS PROVEEDOR,
        CAST(y.FechaRecibido AS DATE) AS FCOMPRA,
        DATEDIFF(day, y.FechaRecibido, GETDATE()) AS DIAS,
        CASE
            WHEN DATEDIFF(day, y.FechaRecibido, GETDATE()) < 15 THEN '< 15'
            WHEN DATEDIFF(day, y.FechaRecibido, GETDATE()) <= 30 THEN '15 - 30'
            WHEN DATEDIFF(day, y.FechaRecibido, GETDATE()) <= 70 THEN '30 - 70'
            WHEN DATEDIFF(day, y.FechaRecibido, GETDATE()) <= 90 THEN '70 - 90'
            ELSE '> 90'
        END AS EDAD,
        y.Precio AS NCOSTO,
        y.Precio AS COSTO,
        RTRIM(LTRIM(y.Modelo)) AS CNOM_PROD,
        RTRIM(LTRIM(m.MARCA)) AS MARCA,
        RTRIM(LTRIM(m.MODELO)) AS MODELO,
        'EQUIPOS' AS LINEA,
        'EQUIPOS' AS SUBLINEA,
        UPPER(RTRIM(LTRIM(COALESCE(t.ALMACEN, REPLACE(y.NombrePV, 'YALI-', ''))))) AS ALMACEN,
        'AMAZONÍA' AS EMPRESA,
        pv.PRECIO AS PRECIO_VTA
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
        SELECT RTRIM(LTRIM(CNOM_PROD)) AS CNOM_NORM, MAX(PRECIO) AS PRECIO
        FROM [192.168.3.101,1900\MSSQL_log].[Distribuidora].[dbo].[WOLAP_PRECIOS_DETALLISTA]
        GROUP BY RTRIM(LTRIM(CNOM_PROD))
    ) pv ON RTRIM(LTRIM(y.Modelo)) = pv.CNOM_NORM
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
    );
END
