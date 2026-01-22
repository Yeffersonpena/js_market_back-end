-- =============================================
-- SP: Seguimiento de Incentivo - Casos y Cargadores V8
-- Descripción: Muestra el seguimiento de ventas de casos y cargadores V8
--              para incentivo por cuotas. Muestra todos los vendedores con
--              su progreso y cuánto les falta para alcanzar las metas.
-- =============================================
CREATE PROCEDURE dbo.sp_SeguimientoIncentivo_CascosCargadoresV8
    @FechaInicio DATE,
    @FechaFin DATE,
    @MetaTop3 MONEY = 2500,
    @MetaSorteo MONEY = 2000
AS
BEGIN
    SET NOCOUNT ON;

    -- Validación de parámetros
    IF @FechaInicio IS NULL OR @FechaFin IS NULL
    BEGIN
        RAISERROR('Las fechas de inicio y fin son obligatorias.', 16, 1);
        RETURN;
    END;

    IF @FechaInicio > @FechaFin
    BEGIN
        RAISERROR('La fecha de inicio no puede ser mayor a la fecha de fin.', 16, 1);
        RETURN;
    END;

    -- Códigos de productos: Casos y Cargadores V8
    DECLARE @CodigosProductos TABLE (COD_PRODUCTO CHAR(15));
    INSERT INTO @CodigosProductos VALUES
        ('001619'), ('001714'), ('001716'), ('001713'),
        ('001715'), ('001712'), ('001711'),
        ('001654'), ('001653'), ('001556'), ('001573'),
        ('001668'), ('001669'), ('001652'), ('001742'),
        ('001743'), ('001553'), ('001574');

    -- Query principal
    SELECT
        z.[ZONA] AS [ALMACEN],
        v.COD_VENDEDOR,
        v.[NOM_VENDEDOR],
        COUNT(DISTINCT CAST(v.[FEC_EMISION] AS DATE)) AS [DIAS_VENTA],
        COUNT(DISTINCT v.[COD_PRODUCTO]) AS [PRODUCTOS_DIFERENTES],
        ISNULL(SUM(v.[PRECIO_VTA]), 0) AS [TOTAL_FACTURADO],
        -- Indicadores de cumplimiento y progreso
        CASE
            WHEN ISNULL(SUM(v.[PRECIO_VTA]), 0) >= @MetaTop3 THEN 'CUMPLE TOP 3'
            WHEN ISNULL(SUM(v.[PRECIO_VTA]), 0) >= @MetaSorteo THEN 'CUMPLE SORTEO'
            ELSE 'EN PROGRESO'
        END AS [ESTADO_INCENTIVO],
        -- Cuánto falta para cada meta
        CASE
            WHEN ISNULL(SUM(v.[PRECIO_VTA]), 0) >= @MetaTop3 THEN 0
            ELSE @MetaTop3 - ISNULL(SUM(v.[PRECIO_VTA]), 0)
        END AS [FALTA_PARA_TOP3],
        CASE
            WHEN ISNULL(SUM(v.[PRECIO_VTA]), 0) >= @MetaSorteo THEN 0
            ELSE @MetaSorteo - ISNULL(SUM(v.[PRECIO_VTA]), 0)
        END AS [FALTA_PARA_SORTEO],
        -- Ranking para identificar top 3
        ROW_NUMBER() OVER (ORDER BY ISNULL(SUM(v.[PRECIO_VTA]), 0) DESC) AS [RANKING],
        -- Metas para referencia
        @MetaTop3 AS [META_TOP3],
        @MetaSorteo AS [META_SORTEO]
    FROM
        [DISTRIBUTOR_DATAMART].[dbo].[DD_WOLAP_VENTA_ANALISIS_DETALLADO] v
        INNER JOIN @CodigosProductos cp ON v.[COD_PRODUCTO] = cp.COD_PRODUCTO
        CROSS APPLY (
            VALUES (
                CASE
                    WHEN v.COD_VENDEDOR IN (148, 225, 279) THEN 'Huánuco'
                    WHEN v.COD_VENDEDOR IN (185, 277, 278) THEN 'Pucallpa'
                    WHEN v.COD_VENDEDOR IN (221, 276) THEN 'Huancayo'
                    WHEN LTRIM(RTRIM(v.[ALMACEN])) = 'LOG - AREQUIPA' THEN 'Arequipa'
                    WHEN LTRIM(RTRIM(v.[ALMACEN])) = 'La Merced' THEN 'Huancayo'
                    ELSE LTRIM(RTRIM(v.[ALMACEN]))
                END
            )
        ) z([ZONA])
    WHERE
        CAST(v.[FEC_EMISION] AS DATE) >= @FechaInicio
        AND CAST(v.[FEC_EMISION] AS DATE) <= @FechaFin
        AND v.[PROD_LINEA] IN ('EQUIPOS', 'ACCESORIOS')
        AND LTRIM(RTRIM(v.[ALMACEN])) <> 'E-COMMERCE'
        AND v.cod_cliente <> '00026087'
    GROUP BY
        z.[ZONA],
        v.COD_VENDEDOR,
        v.[NOM_VENDEDOR]
    ORDER BY
        [TOTAL_FACTURADO] DESC;

END;
GO

