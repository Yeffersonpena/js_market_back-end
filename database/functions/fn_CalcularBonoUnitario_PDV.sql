CREATE   FUNCTION dbo.fn_CalcularBonoUnitario_PDV(
    @tipoPDV VARCHAR(30),
    @zonal VARCHAR(30),
    @venta_avance INT,
    @ratio DECIMAL(5, 2),
    @cantidadCalidad INT,
    @año INT,
    @mes INT
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @bonoUnitario DECIMAL(18, 2) = 0;
    DECLARE @fechaPeriodo DATE = DATEFROMPARTS(@año, @mes, 1);
	SET @tipoPDV = CASE 
                 WHEN @tipoPDV LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM'
                 ELSE @tipoPDV 
               END;
    SET @bonoUnitario = 
        CASE
            WHEN ISNULL(@tipoPDV, '') = 'PDV REGULAR' THEN 
                IIF(@ratio >= 20,
                    CASE 
                        WHEN @venta_avance BETWEEN 5 AND 10 THEN IIF(@ratio >= 50, 1.5, 0.5)
                        WHEN @venta_avance BETWEEN 11 AND 20 THEN IIF(@ratio >= 50, 2.5, 1.5)
                        WHEN @venta_avance BETWEEN 21 AND 40 THEN IIF(@ratio >= 50, 3.0, 2.0)
                        WHEN @venta_avance BETWEEN 41 AND 80 THEN IIF(@ratio >= 50, 3.5, 2.5)
                        WHEN @venta_avance >= 81 THEN IIF(@ratio >= 50, 4.0, 3.0)
                        WHEN (@año > 2025 OR (@año = 2025 AND @mes >= 9)) AND @venta_avance >= 101 THEN IIF(@ratio >= 50, 4.5, 3.5)
                        ELSE 0
                    END,
                    0
                )
            WHEN ISNULL(@tipoPDV, '') LIKE 'PDV PREMIUM%' THEN
                CASE
                    -- Lógica estricta por rango de ventas para LIMA SUR
                    WHEN ISNULL(@zonal, '') LIKE '%LIMA SUR%' THEN
                        ISNULL((
                            SELECT TOP 1 b.bono
                            FROM dbo.BonoEscala b
                            WHERE b.tipo_pdv = @tipoPDV
                              AND ISNULL(@zonal, '') LIKE b.zonal_pattern
                              AND @fechaPeriodo BETWEEN b.fecha_inicio AND ISNULL(b.fecha_fin, @fechaPeriodo)
                              AND @venta_avance BETWEEN b.rango_min AND b.rango_max
                              AND @ratio >= b.ratio_min
                              AND @cantidadCalidad >= ISNULL(b.cantidad_calidad_min, 0)
                            ORDER BY b.ratio_min DESC, b.bono DESC
                        ), 0)
                    -- Lógica "la calidad manda" para REGIONES (corregida sin CTE)
                    ELSE
                        ISNULL((
                            SELECT TOP 1 b.bono
                            FROM dbo.BonoEscala b
                            WHERE b.tipo_pdv = @tipoPDV
                              AND b.zonal_pattern = 'REGIONES'
                              AND @fechaPeriodo BETWEEN b.fecha_inicio AND ISNULL(b.fecha_fin, @fechaPeriodo)
                              AND @venta_avance >= (
                                  SELECT MIN(b2.rango_min) 
                                  FROM dbo.BonoEscala b2 
                                  WHERE b2.tipo_pdv = @tipoPDV 
                                    AND b2.zonal_pattern = 'REGIONES'
                                    AND @fechaPeriodo BETWEEN b2.fecha_inicio AND ISNULL(b2.fecha_fin, @fechaPeriodo)
                              )
                              AND @cantidadCalidad >= ISNULL(b.cantidad_calidad_min, 0)
                              AND @ratio >= b.ratio_min
                            ORDER BY b.cantidad_calidad_min DESC, b.ratio_min DESC
                        ), 0)
                END
            ELSE 0
        END;

    RETURN @bonoUnitario;
END;