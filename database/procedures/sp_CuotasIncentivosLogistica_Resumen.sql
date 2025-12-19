-- =============================================
-- Stored Procedure: sp_CuotasIncentivosLogistica_Resumen
-- Descripción: Obtiene resumen de ventas por zonal con cuotas e incentivos
--              Muestra ventas por día del mes, totales, cuotas y bonos alcanzados
-- Parámetros:
--   @fecha_inicio: Fecha de inicio del período
--   @fecha_fin: Fecha de fin del período
--   @categoria: 'EQUIPOS' o 'ACCESORIOS'
-- =============================================
CREATE PROCEDURE [dbo].[sp_CuotasIncentivosLogistica_Resumen]
    @fecha_inicio DATE,
    @fecha_fin DATE,
    @categoria VARCHAR(20) = 'EQUIPOS'
AS
BEGIN
    SET NOCOUNT ON;

    -- Validar parámetros
    IF @fecha_inicio IS NULL OR @fecha_fin IS NULL
    BEGIN
        RAISERROR('Las fechas de inicio y fin son obligatorias', 16, 1);
        RETURN;
    END

    IF @fecha_inicio > @fecha_fin
    BEGIN
        RAISERROR('La fecha de inicio no puede ser mayor a la fecha de fin', 16, 1);
        RETURN;
    END

    IF @categoria NOT IN ('EQUIPOS', 'ACCESORIOS')
    BEGIN
        RAISERROR('La categoría debe ser EQUIPOS o ACCESORIOS', 16, 1);
        RETURN;
    END

    -- Variables para SQL dinámico
    DECLARE @sql NVARCHAR(MAX);
    DECLARE @columnasPivot NVARCHAR(MAX) = '';
    DECLARE @columnasSelect NVARCHAR(MAX) = '';
    DECLARE @columnasSuma NVARCHAR(MAX) = '';
    DECLARE @columnasSumaTotal NVARCHAR(MAX) = '';
    DECLARE @fechaActual DATE = @fecha_inicio;

    -- Construir lista de días del período para PIVOT
    WHILE @fechaActual <= @fecha_fin
    BEGIN
        DECLARE @dia INT = DAY(@fechaActual);
        DECLARE @diaStr VARCHAR(2) = CAST(@dia AS VARCHAR(2));

        IF @columnasPivot <> ''
            SET @columnasPivot = @columnasPivot + ', ';
        SET @columnasPivot = @columnasPivot + '[' + @diaStr + ']';

        IF @columnasSelect <> ''
            SET @columnasSelect = @columnasSelect + ', ';
        SET @columnasSelect = @columnasSelect + 'ISNULL([' + @diaStr + '], 0) AS [DIA_' + @diaStr + ']';

        IF @columnasSuma <> ''
            SET @columnasSuma = @columnasSuma + ' + ';
        SET @columnasSuma = @columnasSuma + 'ISNULL([' + @diaStr + '], 0)';

        IF @columnasSumaTotal <> ''
            SET @columnasSumaTotal = @columnasSumaTotal + ', ';
        SET @columnasSumaTotal = @columnasSumaTotal + 'SUM([DIA_' + @diaStr + ']) AS [DIA_' + @diaStr + ']';

        SET @fechaActual = DATEADD(DAY, 1, @fechaActual);
    END

    -- Construir SQL dinámico
    SET @sql = N'
    WITH VentasPorDia AS (
        SELECT
            CAST([FEC_EMISION] AS DATE) AS [FECHA],
            DAY(CAST([FEC_EMISION] AS DATE)) AS [DIA_MES],
            CASE
                WHEN LTRIM(RTRIM([ALMACEN])) = ''LOG - AREQUIPA'' THEN ''AREQUIPA''
                WHEN LTRIM(RTRIM([ALMACEN])) = ''La Merced'' THEN ''HUANCAYO''
                WHEN LTRIM(RTRIM([ALMACEN])) LIKE ''%LIMA SUR%'' THEN ''LIMASUR''
                ELSE UPPER(LTRIM(RTRIM([ALMACEN])))
            END AS [ZONAL],
            SUM([PRECIO_VTA]) AS [PRECIO_VTA]
        FROM [DISTRIBUTOR_DATAMART].[dbo].[DD_WOLAP_VENTA_ANALISIS_DETALLADO]
        WHERE CAST([FEC_EMISION] AS DATE) >= @fecha_inicio
          AND CAST([FEC_EMISION] AS DATE) <= @fecha_fin
          AND [PROD_LINEA] = @categoria
          AND LTRIM(RTRIM([ALMACEN])) <> ''E-COMMERCE''
          AND LTRIM(RTRIM([ALMACEN])) IS NOT NULL
          AND LTRIM(RTRIM([ALMACEN])) <> ''''
        GROUP BY
            CAST([FEC_EMISION] AS DATE),
            DAY(CAST([FEC_EMISION] AS DATE)),
            CASE
                WHEN LTRIM(RTRIM([ALMACEN])) = ''LOG - AREQUIPA'' THEN ''AREQUIPA''
                WHEN LTRIM(RTRIM([ALMACEN])) = ''La Merced'' THEN ''HUANCAYO''
                WHEN LTRIM(RTRIM([ALMACEN])) LIKE ''%LIMA SUR%'' THEN ''LIMASUR''
                ELSE UPPER(LTRIM(RTRIM([ALMACEN])))
            END
    ),
    VentasAgrupadas AS (
        SELECT
            [ZONAL],
            [DIA_MES],
            SUM([PRECIO_VTA]) AS [PRECIO_VTA]
        FROM VentasPorDia
        GROUP BY [ZONAL], [DIA_MES]
    ),
    VentasPivot AS (
        SELECT
            [ZONAL],
            ' + @columnasSelect + ',
            (' + @columnasSuma + ') AS [TOTAL_GENERAL]
        FROM (
            SELECT [ZONAL], [DIA_MES], [PRECIO_VTA]
            FROM VentasAgrupadas
        ) AS SourceTable
        PIVOT (
            SUM([PRECIO_VTA])
            FOR [DIA_MES] IN (' + @columnasPivot + ')
        ) AS PivotTable
    ),
    CuotasIncentivos AS (
        SELECT
            [zonal],
            [categoria],
            [cuota1],
            [bono1],
            [cuota2],
            [bono2]
        FROM [dbo].[cuotas_incentivos_logistica]
        WHERE [categoria] = @categoria
          AND [fecha_inicio] <= @fecha_fin
          AND [fecha_fin] >= @fecha_inicio
          AND [activo] = 1
    ),
    VentasConCuotas AS (
        SELECT
            vp.[ZONAL],
            ' + @columnasSelect + ',
            vp.[TOTAL_GENERAL],
            ci.[cuota1],
            ci.[cuota2],
            CASE
                WHEN vp.[TOTAL_GENERAL] >= ci.[cuota2] THEN ''CUOTA 2''
                WHEN vp.[TOTAL_GENERAL] >= ci.[cuota1] THEN ''CUOTA 1''
                ELSE ''-''
            END AS [CUOTA_ALCANZADA],
            CASE
                WHEN vp.[TOTAL_GENERAL] >= ci.[cuota2] THEN ci.[bono2]
                WHEN vp.[TOTAL_GENERAL] >= ci.[cuota1] THEN ci.[bono1]
                ELSE 0
            END AS [BONO]
        FROM VentasPivot vp
        LEFT JOIN CuotasIncentivos ci ON vp.[ZONAL] = ci.[zonal]
    )
    SELECT
        [ZONAL],
        ' + @columnasSelect + ',
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
        [ZONAL];
    ';

    -- Ejecutar SQL dinámico
    EXEC sp_executesql @sql,
        N'@fecha_inicio DATE, @fecha_fin DATE, @categoria VARCHAR(20)',
        @fecha_inicio, @fecha_fin, @categoria;

END;

