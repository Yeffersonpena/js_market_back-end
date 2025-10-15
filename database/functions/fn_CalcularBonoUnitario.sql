CREATE FUNCTION dbo.fn_CalcularBonoUnitario(
    @tipoPDV VARCHAR(30),
    @zonal VARCHAR(30),
    @venta_avance INT,
    @ratio DECIMAL(5, 2),
    @cantidadCalidad INT,
    @año int,
    @mes int
    
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
	DECLARE @bonoUnitario DECIMAL(18, 2) = 0;

DECLARE @fechaPeriodo DATE = DATEFROMPARTS(@año, @mes, 1);

SET
@bonoUnitario = 
    CASE
	WHEN ISNULL(@tipoPDV, '') = 'PDV REGULAR' THEN 
            IIF(@ratio >= 20,
                -- Si cumple el ratio, se aplica la lógica de escalas original.
                CASE 
                    WHEN @venta_avance BETWEEN 5 AND 10 THEN IIF(@ratio >= 50, 1.5, 0.5)
                    WHEN @venta_avance BETWEEN 11 AND 20 THEN IIF(@ratio >= 50, 2.5, 1.5)
                    WHEN @venta_avance BETWEEN 21 AND 40 THEN IIF(@ratio >= 50, 3.0, 2.0)
                    WHEN @venta_avance BETWEEN 41 AND 80 THEN IIF(@ratio >= 50, 3.5, 2.5)
                    WHEN @venta_avance >= 81 THEN IIF(@ratio >= 50, 4.0, 3.0)
                    --WHEN @venta_avance BETWEEN 81 AND 100 THEN IIF(@ratio >= 50, 4.0, 3.0)
                    WHEN (@año > 2025 OR (@año = 2025 AND @mes >= 9))
	                 AND @venta_avance >= 101
	                THEN IIF(@ratio >= 50, 4.5, 3.5)
                    ELSE 0
                END,
                -- Si NO cumple el ratio, el bono es 0.
                0
            )
	WHEN ISNULL(@tipoPDV, '') LIKE 'PDV PREMIUM%' THEN 
            CASE
		WHEN ISNULL(@zonal, '') LIKE '%LIMA SUR%' THEN
			    ISNULL((
			        SELECT TOP 1 b.bono
			        FROM dbo.BonoEscala b
			        WHERE b.tipo_pdv = 'PDV PREMIUM'
			          AND ISNULL(@zonal, '') LIKE b.zonal_pattern
			          AND b.fecha_inicio <= @fechaPeriodo
			          AND (b.fecha_fin IS NULL OR b.fecha_fin >= @fechaPeriodo)
			          AND @venta_avance BETWEEN b.rango_min AND b.rango_max
			          AND @ratio >= b.ratio_min
			          AND @cantidadCalidad >= ISNULL(b.cantidad_calidad_min, 0)
			        ORDER BY b.rango_min, b.ratio_min DESC
			    ), 0)
		ELSE
		-- Otras zonales
                    /*CASE 
                        --WHEN (@año < 2025 OR (@año = 2025 AND @mes < 9)) and @venta_avance BETWEEN 80 AND 149 THEN 2.0
	                    WHEN (@año < 2025 OR (@año = 2025 AND @mes < 9)) 
				         AND @venta_avance BETWEEN 80 AND 149 
				         THEN IIF(@cantidadCalidad >= 45, 2.0, 0)
                        WHEN @venta_avance BETWEEN 150 AND 220 THEN IIF(@cantidadCalidad >= 45, IIF(@ratio >= 45, 5.0, 3.5), IIF(@ratio >= 45, 2.0, 0))
                        WHEN @venta_avance BETWEEN 221 AND 300 THEN IIF(@cantidadCalidad >= 65, IIF(@ratio >= 45, 5.5, 4.0), IIF(@ratio >= 45, 6.0, 3.5))
                        WHEN @venta_avance BETWEEN 301 AND 90000 THEN IIF(@cantidadCalidad >= 100, IIF(@ratio >= 45, 6.0, 4.5), IIF(@ratio >= 45, 6.5, 4.0))
                        ELSE 0
                    END*/
		CASE
			-- Rango especial antes de septiembre 2025
		    WHEN (@año < 2025
						OR (@año = 2025
							AND @mes < 9))
					AND @venta_avance BETWEEN 80 AND 149 
		         THEN IIF(@cantidadCalidad >= 45, 2.0, 0)
					-- Si tiene al menos 150 ventas, manda la cantidadCalidad
					WHEN @venta_avance >= 150
					AND @cantidadCalidad >= 100
		         THEN IIF(@ratio >= 45, 6.0, 4.5)
					-- como rango máximo (301–90000)
					WHEN @venta_avance >= 150
					AND @cantidadCalidad >= 65
		         THEN IIF(@ratio >= 45, 5.5, 4.0)
					-- como rango de 221–300
					WHEN @venta_avance >= 150
					AND @cantidadCalidad >= 45
		         THEN IIF(@ratio >= 45, 5.0, 3.5)
					-- como rango de 150–220
					-- Si no cumple calidad suficiente o ventas mínimas
					ELSE 0
				END
	END
	ELSE 0
END;

RETURN @bonoUnitario;
END;