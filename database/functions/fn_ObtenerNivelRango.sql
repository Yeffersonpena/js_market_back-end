CREATE FUNCTION dbo.fn_ObtenerNivelRango(
    @ventaPrepagoLimitada INT,
    @año INT,
    @mes INT
)
RETURNS INT
AS
BEGIN
    DECLARE @nivelRango INT = NULL;
    DECLARE @fechaPeriodo DATE = DATEFROMPARTS(@año, @mes, 1);
    
    -- Si ventas > 150, limitar a 150 (máximo rango en noviembre)
    -- Esto puede ajustarse según el período si cambian los rangos máximos
    DECLARE @ventasParaBuscar INT = CASE WHEN @ventaPrepagoLimitada > 150 THEN 150 ELSE @ventaPrepagoLimitada END;
    
    -- Buscar nivel_rango en BonoEscala del período especificado
    -- Para noviembre 2025: todos los tipos usan 'TODAS', así que buscamos cualquier registro
    -- que coincida con el rango de ventas en el período especificado
    SELECT TOP 1 @nivelRango = nivel_rango
    FROM dbo.BonoEscala
    WHERE @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo)
      AND @ventasParaBuscar >= rango_min
      AND @ventasParaBuscar <= rango_max
      AND nivel_rango IS NOT NULL  -- Solo registros con nivel_rango poblado
    ORDER BY nivel_rango DESC;  -- Si hay múltiples coincidencias, tomar el mayor nivel
    
    RETURN ISNULL(@nivelRango, 0);
END;

