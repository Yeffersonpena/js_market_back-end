CREATE FUNCTION [dbo].[fn_UnitarioRec]
(
    @dni INT,
    @anio INT,
    @mes INT,
	@tipo varchar(30)
)
RETURNS DECIMAL(18,2)
AS
BEGIN
    DECLARE @ratio DECIMAL(5,2);
    DECLARE @totalVentas INT;
    DECLARE @bonoPorVenta DECIMAL(18,2);

    -- Calcular el ratio de recarga total sobre avance prepago
    SELECT @ratio = ROUND(
        (CAST(RECARGA_TOTAL AS DECIMAL(10,2)) / 
         NULLIF(CAST([AVANCE PREPAGO] AS DECIMAL(10,2)), 0) * 100), 0
    )
    FROM [dbo].[VI_AVANCES_INFO_VENDEDOR] v 
    WHERE v.DNI_RESPONSABLE = @dni;

    -- Calcular total de ventas
    SELECT @totalVentas = COUNT(*) 
    FROM dbo.PDV_OUT_FUNNEL
    WHERE DNI_RESPONSABLE = @dni
      AND YEAR(fecha) = @anio
      AND MONTH(fecha) = @mes;

    -- Determinar el bono por cada venta según el tipo y la tabla
    SET @bonoPorVenta = 
        CASE 
            WHEN @tipo = 'PDV REGULAR' THEN 
                CASE 
                    WHEN @totalVentas BETWEEN 1 AND 10 THEN CASE WHEN @ratio >= 50 THEN 1.5 ELSE 0.5 END
                    WHEN @totalVentas BETWEEN 11 AND 20 THEN CASE WHEN @ratio >= 50 THEN 2.5 ELSE 1.5 END
                    WHEN @totalVentas BETWEEN 21 AND 40 THEN CASE WHEN @ratio >= 50 THEN 3.0 ELSE 2.0 END
                    WHEN @totalVentas BETWEEN 41 AND 80 THEN CASE WHEN @ratio >= 50 THEN 3.5 ELSE 2.5 END
                    WHEN @totalVentas BETWEEN 81 AND 149 THEN CASE WHEN @ratio >= 50 THEN 4.0 ELSE 3.0 END
                    ELSE 0
                END
            WHEN @tipo = 'PDV PREMIUM' THEN 
				CASE 
					WHEN @totalVentas >=80 AND @totalVentas<150 THEN 2.0
                    WHEN @totalVentas BETWEEN 150 AND 250 THEN CASE WHEN @ratio >= 50 THEN 5.0 ELSE 4.0 END
                    WHEN @totalVentas >= 251 THEN CASE WHEN @ratio >= 50 THEN 6.0 ELSE 5.0 END
                    ELSE 0
                END
            ELSE 0
        END;

    RETURN @bonoPorVenta;
END;
GO


