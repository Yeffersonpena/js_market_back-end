CREATE FUNCTION [dbo].[fn_UnitarioCalidadMM](
    @DNI_VENDEDOR INT,
    @dateStart DATE, 
    @dateUpdateCalidad DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @PAGO_UNITARIO INT = 0;
    DECLARE @cantidadCalidad INT = 0;

    SELECT @cantidadCalidad = COUNT(1)
    FROM dbo.PDV_OUT_FUNNEL 
    WHERE 
        DNI_VENDEDOR = CAST(@DNI_VENDEDOR AS VARCHAR(50)) AND
        TRY_CONVERT(DATE, fecha) BETWEEN @dateStart AND @dateUpdateCalidad AND 
        CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado');

    IF @cantidadCalidad < 15
    BEGIN
        RETURN 0;
    END

    SELECT @PAGO_UNITARIO = 
        CASE 
            -- Verificamos si existe al menos una venta en los meses de Junio, Julio o Agosto de 2025
            WHEN MAX(CASE WHEN MONTH(TRY_CONVERT(DATE, FECHA)) IN (6,7,8) AND YEAR(TRY_CONVERT(DATE, FECHA)) = 2025 THEN 1 ELSE 0 END) = 1
            THEN 5  -- ANTIGUO

            -- Verificamos si existe al menos una venta en Septiembre de 2025
            WHEN MAX(CASE WHEN MONTH(TRY_CONVERT(DATE, FECHA)) = 9 AND YEAR(TRY_CONVERT(DATE, FECHA)) = 2025 THEN 1 ELSE 0 END) = 1
            THEN 8  -- NUEVO

            ELSE 0  -- SIN_CLASIFICAR
        END
    FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
    WHERE 
        DNI_VENDEDOR = CAST(@DNI_VENDEDOR AS VARCHAR(50)) AND 
        TRY_CONVERT(DATE, FECHA) IS NOT NULL;
    
    -- Retornamos el valor calculado
    RETURN @PAGO_UNITARIO;
END;