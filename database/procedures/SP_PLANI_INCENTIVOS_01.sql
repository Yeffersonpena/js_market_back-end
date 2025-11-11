EXEC SP_PLANI_INCENTIVOS_01 '2025-11-07', '2025-11-15', '%SMART%10%64%', 7, 15, 'EQUIPOS'

ALTER PROCEDURE SP_PLANI_INCENTIVOS_01
(
    @FECHA_INICIO      DATE,
    @FECHA_FIN         DATE,
    @LLAVE             VARCHAR(100),	--'%SMART%10%64%'
    @MINIMO_CANDADO    INT,
    @MAXIMO_CANDADO    INT,
    @TIPO_PRODUCTO     VARCHAR(20)      -- Ejemplo: 'ACCESORIOS', 'EQUIPOS'
)
AS
BEGIN
    SET NOCOUNT ON;

    -----------------------------------------------------------
    -- TABLAS TEMPORALES
    -----------------------------------------------------------

    IF OBJECT_ID('tempdb..#MAESTRA_VENDEDOR') IS NOT NULL DROP TABLE #MAESTRA_VENDEDOR;
    IF OBJECT_ID('tempdb..#DEUDA') IS NOT NULL DROP TABLE #DEUDA;
    IF OBJECT_ID('tempdb..#VENTA_RANGO') IS NOT NULL DROP TABLE #VENTA_RANGO;
    IF OBJECT_ID('tempdb..#MONTO_VENTA') IS NOT NULL DROP TABLE #MONTO_VENTA;
    IF OBJECT_ID('tempdb..#CANDADO') IS NOT NULL DROP TABLE #CANDADO;

    -----------------------------------------------------------
    -- 1. CREA TABLA DE VENDEDORES
    -----------------------------------------------------------

    CREATE TABLE #MAESTRA_VENDEDOR (
        ZONAL VARCHAR(50),
        CODIGO_VENDEDOR VARCHAR(50),
        VENDEDOR VARCHAR(100),
        A�O INT,
        MES INT,
        CLUSTER VARCHAR(50)
    );

    INSERT INTO #MAESTRA_VENDEDOR
    SELECT ZONAL, CODIGO_VENDEDOR, VENDEDOR, A�O, MES, CLUSTER
    FROM tbl_lista_vendedor
    WHERE a�o = YEAR(@FECHA_INICIO)
      AND MES = MONTH(@FECHA_INICIO)
      AND CLUSTER IS NOT NULL;


    -----------------------------------------------------------
    -- 2. DETECTA DEUDA
    -----------------------------------------------------------

    CREATE TABLE #DEUDA (
        VENDEDOR VARCHAR(100),
        DEUDA DECIMAL(18,2)
    );

    INSERT INTO #DEUDA
    SELECT D.VENDEDOR, SUM(D.SALDO) AS DEUDA
    FROM [DD_WOLAP_REGISTRO_VENTA] D
    INNER JOIN #MAESTRA_VENDEDOR M ON D.VENDEDOR = M.VENDEDOR
    WHERE ESTADO <> 'ANULADO'
      AND SALDO > 0
    GROUP BY D.VENDEDOR;


    -----------------------------------------------------------
    -- 3. VENTAS EN RANGO (dos servidores)
    -----------------------------------------------------------

    SELECT * INTO #VENTA_RANGO
    FROM [192.168.3.101,1800\MSSQL_NEW].[Distribuidora].[dbo].[WOLAP_VENTA_ANALISIS_DETALLADO]
    WHERE FEC_EMISION BETWEEN @FECHA_INICIO AND @FECHA_FIN
      AND PROD_LINEA = @TIPO_PRODUCTO;

    INSERT INTO #VENTA_RANGO
    SELECT [TD],[NRODOC],[FEC_EMISION],[COD_CLIENTE],[NOM_CLIENTE],[DIR_CLIENTE],[DISTRITO],[CDOC_IDE],[COD_VENDEDOR]
    ,[NOM_VENDEDOR],[COD_PRODUCTO],[NOM_PRODUCTO],[NOM_PLAN],[CANTIDAD_REF],[PRECIO_VTA],[IMEI],[ICC],[NRO_ASIGNADO]
    ,[ALMACEN],[FONO1],[FONO2],[COD_ALTERNO],[FAX],[REPARTO],[TIPO],[NCOSTO],[PROVEEDOR],[GRUPO_TECNO],[CTIPO_DOC],[CNRO_DOC]
    ,[FEC_COMPRA],[CTIPO_DOC2],[CNRO_DOC2],[PROD_CATEGORIA],[PROD_LINEA],'','',[CCOD_RUTA],[CCOD_MODULO]
    FROM [192.168.3.101,1900\MSSQL_LOG].[Distribuidora].[dbo].[WOLAP_VENTA_ANALISIS_DETALLADO]
    WHERE FEC_EMISION BETWEEN @FECHA_INICIO AND @FECHA_FIN
      AND PROD_LINEA = @TIPO_PRODUCTO;


    -----------------------------------------------------------
    -- 4. MONTO DE VENTAS
    -----------------------------------------------------------

    CREATE TABLE #MONTO_VENTA (
        NOM_VENDEDOR VARCHAR(200),
        PRECIO_VTA DECIMAL(18,2)
    );

    INSERT INTO #MONTO_VENTA
    SELECT NOM_VENDEDOR, SUM(PRECIO_VTA)
    FROM #VENTA_RANGO
    GROUP BY NOM_VENDEDOR;


    -----------------------------------------------------------
    -- 5. CANDADOS
    -----------------------------------------------------------

    CREATE TABLE #CANDADO(
        NOM_VENDEDOR VARCHAR(200),
        NOM_PRODUCTO VARCHAR(200),
        TOTAL_CANDADO INT,
        MARCA_CANDADO VARCHAR(50)
    );

    ;WITH CANDADO_BASE AS (
        SELECT
            NOM_VENDEDOR,
            NOM_PRODUCTO
        FROM #VENTA_RANGO
        WHERE NOM_PRODUCTO LIKE @LLAVE
    )
    INSERT INTO #CANDADO
    SELECT
        CB.NOM_VENDEDOR,
        -- Concatena todas las variantes del producto candado para el vendedor
        STUFF((
            SELECT DISTINCT ', ' + CB2.NOM_PRODUCTO
            FROM CANDADO_BASE CB2
            WHERE CB2.NOM_VENDEDOR = CB.NOM_VENDEDOR
            FOR XML PATH(''), TYPE
        ).value('.', 'NVARCHAR(MAX)'), 1, 2, '') AS NOM_PRODUCTO,
        COUNT(*) AS TOTAL_CANDADO,
        CASE 
            WHEN COUNT(*) >= @MAXIMO_CANDADO THEN 'CANDADO MAXIMO LOGRADO'
            WHEN COUNT(*) >= @MINIMO_CANDADO THEN 'CANDADO MINIMO LOGRADO'
            ELSE 'NO LOGRA CANDADO'
        END
    FROM CANDADO_BASE CB
    GROUP BY CB.NOM_VENDEDOR;


    -----------------------------------------------------------
    -- 6. RESULTADO FINAL
    -----------------------------------------------------------

    SELECT 
        @TIPO_PRODUCTO AS TIPO_PRODUCTO,
        M.*,
        D.DEUDA,
        V.PRECIO_VTA,
        R.NOM_PRODUCTO AS PRODUCTO_CANDADO,
        R.TOTAL_CANDADO,
        ISNULL(R.MARCA_CANDADO, 'NO LOGRA CANDADO') AS MARCA_CANDADO
    FROM #MAESTRA_VENDEDOR M
    LEFT JOIN #DEUDA D         ON M.VENDEDOR = D.VENDEDOR
    LEFT JOIN #MONTO_VENTA V   ON M.VENDEDOR = V.NOM_VENDEDOR
    LEFT JOIN #CANDADO R       ON M.VENDEDOR = R.NOM_VENDEDOR;

END
GO
