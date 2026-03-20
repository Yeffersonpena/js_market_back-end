-- Ventas WOLAP (JSMS) + YALI unificadas con MARCA y MODELO desde DCN_MAESTRO_PRODUCTO.
-- Contingencia YALI: corrige COSTO/NCOSTO tomando Coste_Total desde YALI_VENTAS_TEMPO por llave compuesta validada.
-- @ProdLinea: vacio/NULL = solo EQUIPOS (mismo criterio que sp_Ventas_Incentivo al filtrar por EQUIPOS). YALI solo tiene EQUIPOS.
CREATE PROCEDURE SP_VENTAS_JS_YALI_TEMPO
    @FechaInicio DATE,
    @FechaFin DATE,
    @ProdLinea VARCHAR(30) = NULL
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
        v.NRODOC AS NRODOC,
        CAST(v.FEC_EMISION AS DATE) AS FEC_EMISION,
        REPLACE(LTRIM(RTRIM(v.NOM_PRODUCTO)), '&quot;', '"') AS NOM_PRODUCTO,
        p.MARCA AS MARCA,
        p.MODELO AS MODELO,
        CAST(v.PRECIO_VTA AS DECIMAL(18,4)) AS PRECIO_VTA,
        CAST(v.NCOSTO AS DECIMAL(18,4)) AS NCOSTO,
        CAST(v.NCOSTO * 1.18 AS DECIMAL(18,4)) AS COSTO,
        v.IMEI AS IMEI,
        UPPER(LTRIM(RTRIM(v.ALMACEN))) AS ALMACEN,
        v.PROD_CATEGORIA AS PROD_CATEGORIA,
        v.PROD_LINEA AS PROD_LINEA,
        'JS' AS EMPRESA,
        UPPER(LTRIM(RTRIM(v.NOM_VENDEDOR))) AS NOM_VENDEDOR
    FROM DISTRIBUTOR_DATAMART.dbo.DD_WOLAP_VENTA_ANALISIS_DETALLADO v
    LEFT JOIN MaestroUnico p
        ON REPLACE(RTRIM(LTRIM(v.NOM_PRODUCTO)), '&quot;', '"') = p.CNOM_PROD_NORM
        AND p.rn = 1
    WHERE CAST(v.FEC_EMISION AS DATE) >= @FechaInicio
        AND CAST(v.FEC_EMISION AS DATE) <= @FechaFin
        AND UPPER(LTRIM(RTRIM(v.ALMACEN))) <> 'AMAZONIA'
        AND LTRIM(RTRIM(v.PROD_LINEA)) <> 'CHIPS'
        -- AND v.cod_cliente <> '00026087'
        -- AND v.REPARTO NOT LIKE 'CANAL MASIVO%'
        -- AND v.cdoc_ide NOT IN ('20612606405', '20615283607')
        AND LTRIM(RTRIM(v.PROD_LINEA)) = COALESCE(NULLIF(LTRIM(RTRIM(@ProdLinea)), ''), 'EQUIPOS')

    UNION ALL

    SELECT
        y.Num_Documento AS NRODOC,
        CAST(y.Fecha AS DATE) AS FEC_EMISION,
        REPLACE(LTRIM(RTRIM(y.Descripcion)), '&quot;', '"') AS NOM_PRODUCTO,
        p.MARCA AS MARCA,
        p.MODELO AS MODELO,
        CAST(y.X_SALDO AS DECIMAL(18,4)) AS PRECIO_VTA,
        CAST(tf.Coste_Total AS DECIMAL(18,4)) AS NCOSTO,
        CAST(tf.Coste_Total AS DECIMAL(18,4)) AS COSTO,
        y.Imei_Icc_Sn AS IMEI,
        CASE
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.Punto_Venta, 'YALI-', ''))))) = 'UCAYALI' THEN 'PUCALLPA'
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.Punto_Venta, 'YALI-', ''))))) COLLATE Latin1_General_CI_AI = 'HUANUCO' THEN 'HUANUCO'
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.Punto_Venta, 'YALI-', ''))))) = 'PICHANAQUI' THEN 'LA MERCED'
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.Punto_Venta, 'YALI-', ''))))) = 'PICHARI' THEN 'AYACUCHO'
            WHEN UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.Punto_Venta, 'YALI-', ''))))) = 'QUILLABAMBA' THEN 'CUSCO'
            ELSE UPPER(LTRIM(RTRIM(COALESCE(t.ALMACEN, REPLACE(y.Punto_Venta, 'YALI-', '')))))
        END AS ALMACEN,
        'EQUIPOS' AS PROD_CATEGORIA,
        'EQUIPOS' AS PROD_LINEA,
        'AMAZONÍA' AS EMPRESA,
        UPPER(LTRIM(RTRIM(y.x_vendedor))) AS NOM_VENDEDOR
    FROM DISTRIBUTOR_DATAMART.dbo.YALI_VENTAS y
    LEFT JOIN (
        SELECT
            t1.FechaDia,
            t1.Punto_Venta,
            t1.Imei_Icc_Sn,
            t1.Num_Documento,
            t1.DescCompacta,
            t1.Coste_Total
        FROM (
            SELECT
                CONVERT(date, t.Fecha) AS FechaDia,
                ISNULL(t.Punto_Venta, N'') AS Punto_Venta,
                ISNULL(t.Imei_Icc_Sn, N'') AS Imei_Icc_Sn,
                ISNULL(t.Num_Documento, N'') AS Num_Documento,
                REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(t.Descripcion, N''))), N' ', N''), CHAR(9), N''), CHAR(160), N'') AS DescCompacta,
                t.Coste_Total,
                ROW_NUMBER() OVER (
                    PARTITION BY
                        CONVERT(date, t.Fecha),
                        ISNULL(t.Punto_Venta, N''),
                        ISNULL(t.Imei_Icc_Sn, N''),
                        ISNULL(t.Num_Documento, N''),
                        REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(t.Descripcion, N''))), N' ', N''), CHAR(9), N''), CHAR(160), N'')
                    ORDER BY t.Fecha DESC
                ) AS rn
            FROM DISTRIBUTOR_DATAMART.dbo.YALI_VENTAS_TEMPO t
            WHERE CONVERT(date, t.Fecha) >= @FechaInicio
                AND CONVERT(date, t.Fecha) <= @FechaFin
        ) t1
        WHERE t1.rn = 1
    ) tf
        ON CONVERT(date, y.Fecha) = tf.FechaDia
        AND ISNULL(y.Punto_Venta, N'') = tf.Punto_Venta
        AND ISNULL(y.Imei_Icc_Sn, N'') = tf.Imei_Icc_Sn
        AND ISNULL(y.Num_Documento, N'') = tf.Num_Documento
        AND REPLACE(REPLACE(REPLACE(LTRIM(RTRIM(ISNULL(y.Descripcion, N''))), N' ', N''), CHAR(9), N''), CHAR(160), N'') = tf.DescCompacta
    LEFT JOIN (
        SELECT CSERIE, ALMACEN
        FROM (
            SELECT CSERIE, ALMACEN,
                ROW_NUMBER() OVER (PARTITION BY CSERIE ORDER BY (SELECT NULL)) AS rn
            FROM DISTRIBUTOR_DATAMART.dbo.YALI_SERIES_TRASLADOS
        ) t0
        WHERE t0.rn = 1
    ) t ON y.Imei_Icc_Sn = t.CSERIE
    LEFT JOIN (
        SELECT CNOM_PROD_NORM, MARCA, MODELO
        FROM (
            SELECT
                REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"') AS CNOM_PROD_NORM,
                MARCA,
                MODELO,
                ROW_NUMBER() OVER (PARTITION BY REPLACE(RTRIM(LTRIM(CNOM_PROD)), '&quot;', '"') ORDER BY MARCA, MODELO) AS rn
            FROM DISTRIBUTOR_DATAMART.dbo.DCN_MAESTRO_PRODUCTO
        ) m
        WHERE m.rn = 1
    ) p ON REPLACE(RTRIM(LTRIM(y.Descripcion)), '&quot;', '"') = p.CNOM_PROD_NORM
    WHERE CAST(y.Fecha AS DATE) >= @FechaInicio
        AND CAST(y.Fecha AS DATE) <= @FechaFin
        AND (@ProdLinea IS NULL OR LTRIM(RTRIM(@ProdLinea)) = '' OR LTRIM(RTRIM(@ProdLinea)) = 'EQUIPOS')
    ORDER BY
        FEC_EMISION,
        NRODOC;
END
