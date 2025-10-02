CREATE FUNCTION [dbo].[fn_UnitarioCalidadMM](
    @DNI_VENDEDOR INT,
    @dateStart DATE, 
    @dateUpdateCalidad DATE
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @PAGO_UNITARIO DECIMAL(10,2) = 0;
    DECLARE @cantidadCalidad INT = 0;
    DECLARE @cantidadVentas INT = 0;
    DECLARE @minimoCalidad INT = 15; -- Valor por defecto
    DECLARE @año INT = YEAR(@dateStart);
    DECLARE @mes INT = MONTH(@dateStart);

    -- Obtener mínimo de calidad configurado para el período
    SELECT TOP 1 @minimoCalidad = ISNULL(cantidad_calidad_minima, 15)
    FROM tbl_parametros_calidad_mm
    WHERE año = @año AND mes = @mes;

    -- Contar ventas de calidad del vendedor
    SELECT @cantidadCalidad = COUNT(1)
    FROM dbo.PDV_OUT_FUNNEL 
    WHERE 
        DNI_VENDEDOR = CAST(@DNI_VENDEDOR AS VARCHAR(50)) AND
        TRY_CONVERT(DATE, fecha) BETWEEN @dateStart AND @dateUpdateCalidad AND 
        CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado');

    -- Si no cumple mínimo de calidad configurado, retornar 0
    IF @cantidadCalidad < @minimoCalidad
    BEGIN
        RETURN 0;
    END

    -- Obtener configuración del mes desde tabla de parámetros
    DECLARE @tipoCalculo VARCHAR(20);
    SELECT TOP 1 
        @tipoCalculo = tipo_calculo,
        @PAGO_UNITARIO = valor_unitario
    FROM tbl_parametros_calidad_mm
    WHERE año = @año AND mes = @mes;

    -- Si no encuentra configuración, retornar 0
    IF @tipoCalculo IS NULL
    BEGIN
        RETURN 0;
    END

    -- Manejar según el tipo de cálculo
    IF @tipoCalculo = 'FIJO'
    BEGIN
        -- Para valores fijos (enero-agosto), retornar directamente
        RETURN @PAGO_UNITARIO;
    END
    ELSE IF @tipoCalculo = 'ANTIGUO_NUEVO'
    BEGIN
        -- Lógica especial para septiembre (antiguos vs nuevos)
        SELECT @PAGO_UNITARIO = 
            CASE 
                WHEN MAX(CASE WHEN MONTH(TRY_CONVERT(DATE, FECHA)) IN (6,7,8) AND YEAR(TRY_CONVERT(DATE, FECHA)) = 2025 THEN 1 ELSE 0 END) = 1
                THEN 5  -- ANTIGUO
                WHEN MAX(CASE WHEN MONTH(TRY_CONVERT(DATE, FECHA)) = 9 AND YEAR(TRY_CONVERT(DATE, FECHA)) = 2025 THEN 1 ELSE 0 END) = 1
                THEN 8  -- NUEVO
                ELSE 0
            END
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE DNI_VENDEDOR = CAST(@DNI_VENDEDOR AS VARCHAR(50)) 
          AND TRY_CONVERT(DATE, FECHA) IS NOT NULL;
        
        RETURN @PAGO_UNITARIO;
    END
    ELSE IF @tipoCalculo = 'ESCALA_VENTAS'
    BEGIN
        -- Manejar escalas por ventas (octubre y futuros)
        SELECT @cantidadVentas = COUNT(1)
        FROM dbo.PDV_OUT_FUNNEL 
        WHERE 
            DNI_VENDEDOR = CAST(@DNI_VENDEDOR AS VARCHAR(50)) AND
            YEAR(fecha) = @año AND MONTH(fecha) = @mes;

        SELECT @PAGO_UNITARIO = valor_unitario
        FROM tbl_parametros_calidad_mm
        WHERE año = @año 
          AND mes = @mes 
          AND tipo_calculo = 'ESCALA_VENTAS'
          AND @cantidadVentas BETWEEN ventas_minimas AND ventas_maximas;
    END

    RETURN ISNULL(@PAGO_UNITARIO, 0);
END;