-- Resumen de stock por EMPRESA y MODELO: cuenta por rango de antigüedad (EDAD) y total STOCK.
-- Obtiene el detalle desde sp_Stock_General (sin precios; PRECIO_VTA se rellena en pasos posteriores) y agrupa.
-- Precios YALI (Amazonía): match en dos pasos (1) por CNOM_PROD, (2) por MODELO si quedó NULL; ver comentarios en bloque YALI.
CREATE PROCEDURE sp_Resumen_Stock
    @linea VARCHAR(50) = NULL,
    @almacen VARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #Base (
        TIPO VARCHAR(50),
        CSERIE VARCHAR(50),
        PROVEEDOR VARCHAR(200),
        FCOMPRA DATE,
        DIAS INT,
        EDAD VARCHAR(20),
        NCOSTO DECIMAL(18,4),
        COSTO DECIMAL(18,4),
        CNOM_PROD VARCHAR(200),
        CCOD_PROD VARCHAR(50),
        MARCA VARCHAR(100),
        MODELO VARCHAR(200),
        LINEA VARCHAR(50),
        SUBLINEA VARCHAR(50),
        ALMACEN VARCHAR(100),
        EMPRESA VARCHAR(50),
        PRECIO_VTA DECIMAL(18,4)
    );

    INSERT INTO #Base (TIPO, CSERIE, PROVEEDOR, FCOMPRA, DIAS, EDAD, NCOSTO, COSTO, CNOM_PROD, CCOD_PROD, MARCA, MODELO, LINEA, SUBLINEA, ALMACEN, EMPRESA)
    EXEC sp_Stock_General @linea = @linea, @almacen = @almacen;

    -- Precios JS: una sola consulta al linked server 1800. Match por CCOD_PROD + almacén (TIPO_VENTA_NORM).
    -- RTRIM/LTRIM en campos del linked para normalizar espacios de más.
    CREATE TABLE #PreciosJS (
        CCOD_PROD VARCHAR(50),
        TIPO_VENTA_NORM VARCHAR(100),
        PRECIO DECIMAL(18,4)
    );
    INSERT INTO #PreciosJS (CCOD_PROD, TIPO_VENTA_NORM, PRECIO)
    SELECT
        RTRIM(LTRIM(CAST(ISNULL(d.CCOD_PROD, '') AS VARCHAR(50)))),
        CASE
            WHEN UPPER(RTRIM(LTRIM(REPLACE(ISNULL(d.CNOM_TIPOVENTA, ''), 'JSM - ', '')))) COLLATE Latin1_General_CI_AI = 'HUANUCO' THEN 'HUANUCO'
            ELSE UPPER(RTRIM(LTRIM(REPLACE(ISNULL(d.CNOM_TIPOVENTA, ''), 'JSM - ', ''))))
        END,
        d.PRECIO
    FROM [192.168.3.101,1800\MSSQL_NEW].[Distribuidora].[dbo].[WOLAP_PRECIOS_DETALLISTA] d;

    -- Asignar PRECIO_VTA a #Base: JS por CCOD_PROD + ALMACEN.
    UPDATE b
    SET b.PRECIO_VTA = p.PRECIO
    FROM #Base b
    INNER JOIN (
        SELECT CCOD_PROD, TIPO_VENTA_NORM, MAX(PRECIO) AS PRECIO
        FROM #PreciosJS
        GROUP BY CCOD_PROD, TIPO_VENTA_NORM
    ) p ON RTRIM(LTRIM(ISNULL(b.CCOD_PROD, ''))) = RTRIM(LTRIM(ISNULL(p.CCOD_PROD, '')))
        AND RTRIM(LTRIM(ISNULL(b.ALMACEN, ''))) = RTRIM(LTRIM(ISNULL(p.TIPO_VENTA_NORM, '')))
    WHERE b.EMPRESA = 'JS';

    -- YALI (Amazonía): primera opción tabla local YALI_PRECIO_VENTA. PUNTO_VENTA sin 'YALI-' y mismo CASE que sp_Stock_General (UCAYALI→PUCALLPA, PICHANAQUI→LA MERCED, PICHARI→AYACUCHO, QUILLABAMBA→CUSCO).
    CREATE TABLE #PreciosYaliLocal (
        COD_SAP VARCHAR(50),
        ALMACEN_NORM VARCHAR(100),
        PRECIO DECIMAL(18,4)
    );
    INSERT INTO #PreciosYaliLocal (COD_SAP, ALMACEN_NORM, PRECIO)
    SELECT
        RTRIM(LTRIM(v.COD_SAP)),
        CASE
            WHEN UPPER(LTRIM(RTRIM(REPLACE(ISNULL(v.PUNTO_VENTA, ''), 'YALI-', '')))) = 'UCAYALI' THEN 'PUCALLPA'
            WHEN UPPER(LTRIM(RTRIM(REPLACE(ISNULL(v.PUNTO_VENTA, ''), 'YALI-', '')))) COLLATE Latin1_General_CI_AI = 'HUANUCO' THEN 'HUANUCO'
            WHEN UPPER(LTRIM(RTRIM(REPLACE(ISNULL(v.PUNTO_VENTA, ''), 'YALI-', '')))) = 'PICHANAQUI' THEN 'LA MERCED'
            WHEN UPPER(LTRIM(RTRIM(REPLACE(ISNULL(v.PUNTO_VENTA, ''), 'YALI-', '')))) = 'PICHARI' THEN 'AYACUCHO'
            WHEN UPPER(LTRIM(RTRIM(REPLACE(ISNULL(v.PUNTO_VENTA, ''), 'YALI-', '')))) = 'QUILLABAMBA' THEN 'CUSCO'
            ELSE UPPER(LTRIM(RTRIM(REPLACE(ISNULL(v.PUNTO_VENTA, ''), 'YALI-', ''))))
        END,
        v.PRECIO_VENTA
    FROM DISTRIBUTOR_DATAMART.dbo.YALI_PRECIO_VENTA v;

    UPDATE b
    SET b.PRECIO_VTA = p.PRECIO
    FROM #Base b
    INNER JOIN (
        SELECT COD_SAP, ALMACEN_NORM, MAX(PRECIO) AS PRECIO
        FROM #PreciosYaliLocal
        GROUP BY COD_SAP, ALMACEN_NORM
    ) p ON RTRIM(LTRIM(ISNULL(b.CCOD_PROD, ''))) = RTRIM(LTRIM(p.COD_SAP))
        AND RTRIM(LTRIM(ISNULL(b.ALMACEN, ''))) = RTRIM(LTRIM(p.ALMACEN_NORM))
    WHERE b.EMPRESA = 'AMAZONÍA';

    -- YALI: por ahora solo tabla YALI_PRECIO_VENTA; linked 1900 comentado.
    /*
    CREATE TABLE #PreciosYali (
        CNOM_PROD VARCHAR(200),
        PRECIO DECIMAL(18,4)
    );
    INSERT INTO #PreciosYali (CNOM_PROD, PRECIO)
    SELECT
        RTRIM(LTRIM(REPLACE(ISNULL(d.CNOM_PROD, ''), '&quot;', '"'))),
        d.PRECIO
    FROM [192.168.3.101,1900\MSSQL_log].[Distribuidora].[dbo].[WOLAP_PRECIOS_DETALLISTA] d;

    CREATE TABLE #PreciosYaliAsignados (
        CNOM_PROD VARCHAR(200),
        MODELO VARCHAR(200),
        PRECIO DECIMAL(18,4)
    );
    INSERT INTO #PreciosYaliAsignados (CNOM_PROD, MODELO, PRECIO)
    SELECT
        d.CNOM_PROD,
        d.MODELO,
        COALESCE(
            (SELECT MAX(p2.PRECIO)
             FROM #PreciosYali p2
             WHERE LEN(RTRIM(LTRIM(REPLACE(ISNULL(d.CNOM_PROD, ''), '&quot;', '"')))) > 0
               AND RTRIM(LTRIM(p2.CNOM_PROD)) COLLATE Latin1_General_CI_AI
                   LIKE RTRIM(LTRIM(REPLACE(ISNULL(d.CNOM_PROD, ''), '&quot;', '"'))) COLLATE Latin1_General_CI_AI + '%'),
            (SELECT MAX(p2.PRECIO)
             FROM #PreciosYali p2
             WHERE LEN(RTRIM(LTRIM(ISNULL(d.MODELO, '')))) > 0
               AND RTRIM(LTRIM(p2.CNOM_PROD)) COLLATE Latin1_General_CI_AI
                   LIKE RTRIM(LTRIM(ISNULL(d.MODELO, ''))) COLLATE Latin1_General_CI_AI + '%')
        ) AS PRECIO
    FROM (SELECT DISTINCT CNOM_PROD, MODELO FROM #Base WHERE EMPRESA = 'AMAZONÍA') d;

    UPDATE b
    SET b.PRECIO_VTA = pa.PRECIO
    FROM #Base b
    INNER JOIN #PreciosYaliAsignados pa
        ON b.CNOM_PROD = pa.CNOM_PROD
        AND (b.MODELO = pa.MODELO OR (b.MODELO IS NULL AND pa.MODELO IS NULL))
    WHERE b.EMPRESA = 'AMAZONÍA' AND b.PRECIO_VTA IS NULL AND pa.PRECIO IS NOT NULL;
    */

    SELECT
        EMPRESA,
        MAX(MODELO) AS MODELO,
        SUM(CASE WHEN EDAD = '<15' THEN 1 ELSE 0 END) AS [<15],
        SUM(CASE WHEN EDAD = '15-30' THEN 1 ELSE 0 END) AS [15-30],
        SUM(CASE WHEN EDAD = '30-45' THEN 1 ELSE 0 END) AS [30-45],
        SUM(CASE WHEN EDAD = '45-60' THEN 1 ELSE 0 END) AS [45-60],
        SUM(CASE WHEN EDAD = '60-90' THEN 1 ELSE 0 END) AS [60-90],
        SUM(CASE WHEN EDAD = '>90' THEN 1 ELSE 0 END) AS [>90],
        COUNT(*) AS STOCK,
        AVG(COSTO) AS COSTO,
        MAX(PRECIO_VTA) AS PRECIO_VTA
    FROM #Base
    WHERE (@almacen IS NULL OR RTRIM(LTRIM(@almacen)) = '' OR UPPER(RTRIM(LTRIM(ALMACEN))) = UPPER(RTRIM(LTRIM(@almacen))))
    GROUP BY EMPRESA, COALESCE(MODELO, CNOM_PROD)
    ORDER BY EMPRESA, COALESCE(MODELO, CNOM_PROD);
END
