-- =============================================
-- Stored Procedure: sp_CuotasIncentivosLogistica_Resumen
-- Descripción: Resumen por zonal con ventas (WOLAP + YALI), cuotas y bono
-- Cuotas: DISTRIBUTOR_DATAMART.dbo.incentivo_cuotas_detalle (por @incentivo_id)
-- Parámetros:
--   @incentivo_id: Id en incentivo_cabecera (cuotas vigentes de ese incentivo)
--   @fecha_inicio: Fecha de inicio del período de ventas a sumar
--   @fecha_fin: Fecha de fin del período de ventas a sumar
--   @categoria: 'EQUIPOS', 'ACCESORIOS' o 'TODAS'
-- =============================================
CREATE OR ALTER PROCEDURE sp_CuotasIncentivosLogistica_Resumen
    @incentivo_id INT,
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @categoria VARCHAR(20) = 'EQUIPOS'
AS
BEGIN
    SET NOCOUNT ON;

    IF @incentivo_id IS NULL OR @incentivo_id <= 0
    BEGIN
        RAISERROR('@incentivo_id es obligatorio y debe ser mayor a 0', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (
        SELECT 1
        FROM [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera]
        WHERE [id] = @incentivo_id
          AND [activo] = 1
    )
    BEGIN
        RAISERROR('No existe incentivo activo con el id indicado', 16, 1);
        RETURN;
    END;

    IF @fecha_inicio IS NULL OR @fecha_fin IS NULL
    BEGIN
        RAISERROR('Las fechas de inicio y fin son obligatorias', 16, 1);
        RETURN;
    END;

    IF @fecha_inicio > @fecha_fin
    BEGIN
        RAISERROR('La fecha de inicio no puede ser mayor a la fecha de fin', 16, 1);
        RETURN;
    END;

    SET @categoria = UPPER(LTRIM(RTRIM(@categoria)));

    IF @categoria NOT IN ('EQUIPOS', 'ACCESORIOS', 'TODAS')
    BEGIN
        RAISERROR('La categoría debe ser EQUIPOS, ACCESORIOS o TODAS', 16, 1);
        RETURN;
    END;

    DECLARE @sql NVARCHAR(MAX);
    DECLARE @columnasPivot NVARCHAR(MAX) = '';
    DECLARE @columnasSelectPivot NVARCHAR(MAX) = '';
    DECLARE @columnasSelectFinal NVARCHAR(MAX) = '';
    DECLARE @columnasSumaPivot NVARCHAR(MAX) = '';
    DECLARE @columnasSumaTotal NVARCHAR(MAX) = '';
    DECLARE @fechaActual DATE = @fecha_inicio;

    WHILE @fechaActual <= @fecha_fin
    BEGIN
        DECLARE @dia INT = DAY(@fechaActual);
        DECLARE @diaStr VARCHAR(2) = CAST(@dia AS VARCHAR(2));

        IF @columnasPivot <> ''
            SET @columnasPivot = @columnasPivot + ', ';
        SET @columnasPivot = @columnasPivot + '[' + @diaStr + ']';

        IF @columnasSelectPivot <> ''
            SET @columnasSelectPivot = @columnasSelectPivot + ', ';
        SET @columnasSelectPivot = @columnasSelectPivot + 'ISNULL(pv.[' + @diaStr + '], 0) AS [DIA_' + @diaStr + ']';

        IF @columnasSelectFinal <> ''
            SET @columnasSelectFinal = @columnasSelectFinal + ', ';
        SET @columnasSelectFinal = @columnasSelectFinal + '[DIA_' + @diaStr + ']';

        IF @columnasSumaPivot <> ''
            SET @columnasSumaPivot = @columnasSumaPivot + ' + ';
        SET @columnasSumaPivot = @columnasSumaPivot + 'ISNULL(pv.[' + @diaStr + '], 0)';

        IF @columnasSumaTotal <> ''
            SET @columnasSumaTotal = @columnasSumaTotal + ', ';
        SET @columnasSumaTotal = @columnasSumaTotal + 'SUM([DIA_' + @diaStr + ']) AS [DIA_' + @diaStr + ']';

        SET @fechaActual = DATEADD(DAY, 1, @fechaActual);
    END;

    SET @sql = N'
    ;WITH VentasBase AS (
        SELECT
            CAST(v.[FEC_EMISION] AS DATE) AS FECHA,
            DAY(CAST(v.[FEC_EMISION] AS DATE)) AS DIA_MES,
            UPPER(z.ZONA) AS ZONAL,
            UPPER(LTRIM(RTRIM(v.[PROD_LINEA]))) AS PROD_LINEA,
            CAST(SUM(v.[PRECIO_VTA]) AS DECIMAL(18,4)) AS PRECIO_VTA
        FROM [DISTRIBUTOR_DATAMART].[dbo].[DD_WOLAP_VENTA_ANALISIS_DETALLADO] v
        CROSS APPLY (
            VALUES (
                CASE
                    WHEN v.COD_VENDEDOR IN (148, 225, 279, 280) THEN ''HUANUCO''
                    WHEN v.COD_VENDEDOR IN (185, 277, 278) THEN ''PUCALLPA''
                    WHEN v.COD_VENDEDOR IN (221, 276) THEN ''HUANCAYO''
                    WHEN v.COD_VENDEDOR IN (198) THEN ''AYACUCHO''
                    WHEN v.COD_VENDEDOR IN (281) THEN ''CUSCO''
                    WHEN LTRIM(RTRIM(v.[ALMACEN])) = ''LOG - AREQUIPA'' THEN ''AREQUIPA''
                    WHEN LTRIM(RTRIM(v.[ALMACEN])) = ''La Merced'' THEN ''HUANCAYO''
                    WHEN UPPER(LTRIM(RTRIM(v.[ALMACEN]))) LIKE ''%LIMA SUR%'' THEN ''LIMASUR''
                    ELSE UPPER(LTRIM(RTRIM(v.[ALMACEN])))
                END
            )
        ) z(ZONA)
        WHERE CAST(v.[FEC_EMISION] AS DATE) >= @fecha_inicio
          AND CAST(v.[FEC_EMISION] AS DATE) <= @fecha_fin
          AND v.[PROD_LINEA] != ''CHIPS''
          AND v.cod_cliente <> ''00026087''
          AND v.REPARTO NOT LIKE ''CANAL MASIVO%''
          AND v.cdoc_ide NOT IN (''20612606405'', ''20615283607'')
        GROUP BY
            CAST(v.[FEC_EMISION] AS DATE),
            DAY(CAST(v.[FEC_EMISION] AS DATE)),
            UPPER(z.ZONA),
            UPPER(LTRIM(RTRIM(v.[PROD_LINEA])))

        UNION ALL

        SELECT
            CAST(y.[Fecha] AS DATE) AS FECHA,
            DAY(CAST(y.[Fecha] AS DATE)) AS DIA_MES,
            UPPER(LTRIM(RTRIM(y.[x_zonal]))) AS ZONAL,
            ''EQUIPOS'' AS PROD_LINEA,
            CAST(SUM(y.[X_SALDO]) AS DECIMAL(18,4)) AS PRECIO_VTA
        FROM [DISTRIBUTOR_DATAMART].[dbo].[YALI_VENTAS] y
        WHERE CAST(y.[Fecha] AS DATE) >= @fecha_inicio
          AND CAST(y.[Fecha] AS DATE) <= @fecha_fin
        GROUP BY
            CAST(y.[Fecha] AS DATE),
            DAY(CAST(y.[Fecha] AS DATE)),
            UPPER(LTRIM(RTRIM(y.[x_zonal])))
    ),
    VentasFiltradas AS (
        SELECT
            ZONAL,
            DIA_MES,
            SUM(PRECIO_VTA) AS PRECIO_VTA
        FROM VentasBase
        WHERE
            (@categoria = ''TODAS'')
            OR (@categoria = ''EQUIPOS'' AND PROD_LINEA = ''EQUIPOS'')
            OR (@categoria = ''ACCESORIOS'' AND PROD_LINEA = ''ACCESORIOS'')
        GROUP BY ZONAL, DIA_MES
    ),
    VentasPivot AS (
        SELECT
            pv.[ZONAL],
            ' + @columnasSelectPivot + ',
            (' + @columnasSumaPivot + ') AS [TOTAL_GENERAL]
        FROM (
            SELECT [ZONAL], [DIA_MES], [PRECIO_VTA]
            FROM VentasFiltradas
        ) AS src
        PIVOT (
            SUM([PRECIO_VTA])
            FOR [DIA_MES] IN (' + @columnasPivot + ')
        ) AS pv
    ),
    Cuotas AS (
        SELECT
            UPPER(LTRIM(RTRIM(d.[zonal]))) AS zonal,
            UPPER(LTRIM(RTRIM(d.[categoria]))) AS categoria,
            d.[cuota1],
            d.[bono1],
            d.[cuota2],
            d.[bono2]
        FROM [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cuotas_detalle] d
        INNER JOIN [DISTRIBUTOR_DATAMART].[dbo].[incentivo_cabecera] cab
            ON cab.[id] = d.[incentivo_id]
        WHERE d.[incentivo_id] = @incentivo_id
          AND UPPER(LTRIM(RTRIM(d.[categoria]))) = @categoria
          AND d.[activo] = 1
          AND cab.[activo] = 1
    ),
    VentasConCuotas AS (
        SELECT
            vp.[ZONAL],
            ' + @columnasSelectFinal + ',
            vp.[TOTAL_GENERAL],
            c.[cuota1],
            c.[cuota2],
            CASE
                WHEN vp.[TOTAL_GENERAL] >= c.[cuota2] THEN ''CUOTA 2''
                WHEN vp.[TOTAL_GENERAL] >= c.[cuota1] THEN ''CUOTA 1''
                ELSE ''-''
            END AS [CUOTA_ALCANZADA],
            CASE
                WHEN vp.[TOTAL_GENERAL] >= c.[cuota2] THEN c.[bono2]
                WHEN vp.[TOTAL_GENERAL] >= c.[cuota1] THEN c.[bono1]
                ELSE 0
            END AS [BONO]
        FROM VentasPivot vp
        LEFT JOIN Cuotas c
            ON vp.[ZONAL] COLLATE Latin1_General_CI_AI = c.[zonal] COLLATE Latin1_General_CI_AI
    )
    SELECT
        [ZONAL],
        ' + @columnasSelectFinal + ',
        [TOTAL_GENERAL],
        [cuota1] AS [CUOTA_1],
        [cuota2] AS [CUOTA_2],
        [CUOTA_ALCANZADA],
        [BONO]
    FROM VentasConCuotas
    UNION ALL
    SELECT
        ''Total general'' AS [ZONAL],
        ' + @columnasSumaTotal + ',
        SUM([TOTAL_GENERAL]) AS [TOTAL_GENERAL],
        SUM([cuota1]) AS [CUOTA_1],
        SUM([cuota2]) AS [CUOTA_2],
        NULL AS [CUOTA_ALCANZADA],
        SUM([BONO]) AS [BONO]
    FROM VentasConCuotas
    ORDER BY
        CASE WHEN [ZONAL] = ''Total general'' THEN 1 ELSE 0 END,
        [ZONAL];';

    EXEC sp_executesql
        @sql,
        N'@incentivo_id INT, @fecha_inicio DATE, @fecha_fin DATE, @categoria VARCHAR(20)',
        @incentivo_id,
        @fecha_inicio,
        @fecha_fin,
        @categoria;
END;

