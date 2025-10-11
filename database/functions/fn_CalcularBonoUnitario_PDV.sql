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
    
    -- Mapear zona para BonoEscala (igual que en spCalculoPayment_9)
    DECLARE @zonalPattern VARCHAR(50);
    SET @zonalPattern = CASE 
        WHEN @zonal LIKE '%LIMA SUR%' THEN '%LIMA SUR%'
        WHEN @tipoPDV = 'PDV REGULAR' THEN 'TODAS'
        ELSE 'REGIONES'
    END;
    
    SET @bonoUnitario = 
        CASE
            WHEN ISNULL(@tipoPDV, '') = 'PDV REGULAR' THEN 
                ISNULL((
                    SELECT TOP 1 b.bono
                    FROM dbo.BonoEscala b
                    WHERE b.tipo_pdv = 'PDV REGULAR'
                      AND b.zonal_pattern = @zonalPattern
                      AND @fechaPeriodo BETWEEN b.fecha_inicio AND ISNULL(b.fecha_fin, @fechaPeriodo)
                      AND @venta_avance >= b.rango_min
                      AND @ratio >= b.ratio_min
                      AND @cantidadCalidad >= ISNULL(b.cantidad_calidad_min, 0)
                    ORDER BY 
                        CASE WHEN @venta_avance <= b.rango_max THEN 0 ELSE 1 END,
                        b.rango_max DESC,
                        b.ratio_min DESC, 
                        b.bono DESC
                ), 0)
            WHEN ISNULL(@tipoPDV, '') LIKE 'PDV PREMIUM%' THEN
                CASE
                    -- Lógica estricta por rango de ventas para LIMA SUR
                    WHEN @zonalPattern = '%LIMA SUR%' THEN
                        ISNULL((
                            SELECT TOP 1 b.bono
                            FROM dbo.BonoEscala b
                            WHERE b.tipo_pdv = @tipoPDV
                              AND b.zonal_pattern LIKE @zonalPattern
                              AND @fechaPeriodo BETWEEN b.fecha_inicio AND ISNULL(b.fecha_fin, @fechaPeriodo)
                              AND @venta_avance >= b.rango_min
                              AND @ratio >= b.ratio_min
                              AND @cantidadCalidad >= ISNULL(b.cantidad_calidad_min, 0)
                            ORDER BY 
                                CASE WHEN @venta_avance <= b.rango_max THEN 0 ELSE 1 END,
                                b.rango_max DESC,
                                b.ratio_min DESC, 
                                b.bono DESC
                        ), 0)
                    -- Lógica "la calidad manda" para REGIONES (corregida sin CTE)
                    ELSE
                        ISNULL((
                            SELECT TOP 1 b.bono
                            FROM dbo.BonoEscala b
                            WHERE b.tipo_pdv = @tipoPDV
                              AND b.zonal_pattern = @zonalPattern
                              AND @fechaPeriodo BETWEEN b.fecha_inicio AND ISNULL(b.fecha_fin, @fechaPeriodo)
                              AND @venta_avance >= (
                                  SELECT MIN(b2.rango_min) 
                                  FROM dbo.BonoEscala b2 
                                  WHERE b2.tipo_pdv = @tipoPDV 
                                    AND b2.zonal_pattern = @zonalPattern
                                    AND @fechaPeriodo BETWEEN b2.fecha_inicio AND ISNULL(b2.fecha_fin, @fechaPeriodo)
                              )
                              AND @cantidadCalidad >= ISNULL(b.cantidad_calidad_min, 0)
                              AND @ratio >= b.ratio_min
                            ORDER BY 
                                CASE 
                                    WHEN b.cantidad_calidad_min = (
                                        SELECT MAX(b3.cantidad_calidad_min)
                                        FROM dbo.BonoEscala b3
                                        WHERE b3.tipo_pdv = @tipoPDV
                                          AND b3.zonal_pattern = @zonalPattern
                                          AND @fechaPeriodo BETWEEN b3.fecha_inicio AND ISNULL(b3.fecha_fin, @fechaPeriodo)
                                          AND @cantidadCalidad >= ISNULL(b3.cantidad_calidad_min, 0)
                                    ) THEN 1 ELSE 0 END DESC,
                                b.cantidad_calidad_min DESC,
                                b.ratio_min DESC,
                                b.bono DESC
                        ), 0)
                END
            ELSE 0
        END;

    RETURN @bonoUnitario;
END;