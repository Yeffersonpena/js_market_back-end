create FUNCTION [dbo].[fn_categoriaTable] (@dniResponsable VARCHAR(20), @anio INT, @mes INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @totalVenta INT, @totalRecargas INT, @tipoPDV VARCHAR(20), @bonoPre FLOAT, @ratio DECIMAL(5,2), @rangoStart int, @rangoEnd int;

	SELECT @totalVenta = sum(cantidad) FROM dbo.tbl_venta_log 
    WHERE DNI_RESPONSABLE = @dniResponsable
    AND YEAR(fecha) = @anio 
    AND MONTH(fecha) = @mes

	SELECT @totalRecargas=COUNT(*)
     FROM (
         SELECT DISTINCT *
         FROM dbo.PDV_OUT_FUNNEL
         WHERE DNI_RESPONSABLE = @dniResponsable
           AND YEAR(fecha) = YEAR(GETDATE())
           AND MONTH(fecha) = MONTH(GETDATE())
           AND [RECARGAS>5] = 1
     ) AS SubQuery 

    SELECT TOP 1 @tipoPDV = ACCION_2 
    FROM dbo.PDV_OUT_ENTREGABLE 
    WHERE AÑO = @anio 
    AND DNI_RESPONSABLE = @dniResponsable
    ORDER BY mes DESC;
    SET @ratio = CASE WHEN @totalVenta > 0 THEN ROUND((CAST(@totalRecargas AS DECIMAL(10,2)) / @totalVenta) * 100, 0) ELSE 0 END;

    SET @rangoEnd = 
        CASE 
            WHEN @tipoPDV = 'PDV REGULAR' THEN 
                CASE 
                    WHEN @totalVenta BETWEEN 1 AND 10 THEN CASE WHEN @ratio >= 50 THEN 10 ELSE 0 END
                    WHEN @totalVenta BETWEEN 11 AND 20 THEN CASE WHEN @ratio >= 50 THEN 20 ELSE 0 END
                    WHEN @totalVenta BETWEEN 21 AND 40 THEN CASE WHEN @ratio >= 50 THEN 40 ELSE 0 END
                    WHEN @totalVenta BETWEEN 41 AND 80 THEN CASE WHEN @ratio >= 50 THEN 80 ELSE 0 END
                    WHEN @totalVenta >= 81 THEN CASE WHEN @ratio >= 50 THEN 100 ELSE 0 END
                    ELSE 0
                END
            WHEN @tipoPDV = 'PDV PREMIUM' THEN 
                CASE 
                    WHEN @totalVenta BETWEEN 80 AND 149 THEN 149
                    WHEN @totalVenta BETWEEN 150 AND 250 THEN CASE WHEN @ratio >= 50 THEN 250 ELSE 0 END
                    WHEN @totalVenta >= 251 THEN CASE WHEN @ratio >= 50 THEN 300 ELSE 0 END
                    ELSE 0
                END
            ELSE 0
        END;

    RETURN @rangoEnd;
END;


 SET @bonoPre = 
        CASE 
            WHEN @tipoPDV = 'PDV REGULAR' THEN 
                CASE 
                    WHEN @totalVenta BETWEEN 1 AND 10 THEN CASE WHEN @ratio >= 50 THEN set @rangoEnd=10 ELSE 0 END
                    WHEN @totalVenta BETWEEN 11 AND 20 THEN CASE WHEN @ratio >= 50 THEN set @rangoEnd=20 ELSE 0 END
                    WHEN @totalVenta BETWEEN 21 AND 40 THEN CASE WHEN @ratio >= 50 THEN set @rangoEnd=40 ELSE 0 END
                    WHEN @totalVenta BETWEEN 41 AND 80 THEN CASE WHEN @ratio >= 50 THEN set @rangoEnd=80 ELSE 0 END
                    WHEN @totalVenta >= 81 THEN CASE WHEN @ratio >= 50 THEN set @rangoEnd=100 ELSE 0 END
                    ELSE 0
                END
            WHEN @tipoPDV = 'PDV PREMIUM' THEN 
                CASE 
                    WHEN @totalVenta BETWEEN 80 AND 149 THEN set @rangoEnd=149
                    WHEN @totalVenta BETWEEN 150 AND 250 THEN CASE WHEN @ratio >= 50 THEN set @rangoEnd=250 ELSE 0 END
                    WHEN @totalVenta >= 251 THEN CASE WHEN @ratio >= 50 THEN set @rangoEnd=300 ELSE 0 END
                    ELSE 0
                END
            ELSE 0
        END;

    RETURN @rangoEnd;
END;