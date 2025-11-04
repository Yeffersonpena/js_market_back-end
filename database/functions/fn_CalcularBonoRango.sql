-- Función para calcular el bono por rango (sube/mantiene)
-- Retorna una tabla con: ventas_mes_anterior, rango_mes_anterior, rango_actual, tipo_bono, monto_bono
-- Alta cohesión: toda la lógica de cálculo de bono por rango está aquí
-- Bajo acoplamiento: no depende de lógica específica del SP, solo recibe parámetros

CREATE FUNCTION dbo.fn_CalcularBonoRango(
    @ventasMesActual INT,
    @ventasMesAnterior INT,
    @rangoActual INT,
    @añoActual INT,
    @mesActual INT
)
RETURNS TABLE
AS
RETURN
(
    WITH MaxVentaPeriodo AS (
        -- Obtener el límite máximo de ventas del período actual
        SELECT ISNULL(MAX(rango_max), 150) AS max_venta
        FROM dbo.BonoEscala
        WHERE DATEFROMPARTS(@añoActual, @mesActual, 1) BETWEEN fecha_inicio AND ISNULL(fecha_fin, DATEFROMPARTS(@añoActual, @mesActual, 1))
    ),
    CalculoRangoAnterior AS (
        -- Calcular el rango del mes anterior usando la escala del mes actual
        -- Esto es clave: las ventas de octubre se mapean a la escala de noviembre
        SELECT 
            dbo.fn_ObtenerNivelRango(
                CASE WHEN @ventasMesAnterior > mv.max_venta THEN mv.max_venta ELSE @ventasMesAnterior END,
                @añoActual,  -- Usar el año del mes actual
                @mesActual   -- Usar el mes actual para consultar su escala
            ) AS rango_mes_anterior
        FROM MaxVentaPeriodo mv
    ),
    ComparacionRangos AS (
        SELECT 
            @ventasMesAnterior AS ventas_mes_anterior,
            r.rango_mes_anterior,
            @rangoActual AS rango_actual,
            CASE 
                WHEN @rangoActual > r.rango_mes_anterior THEN 'sube'
                WHEN @rangoActual = r.rango_mes_anterior AND @rangoActual > 0 THEN 'mantiene'
                ELSE NULL
            END AS tipo_bono,
            CASE 
                WHEN @rangoActual > r.rango_mes_anterior THEN @rangoActual  -- Para consultar bono "sube"
                WHEN @rangoActual = r.rango_mes_anterior AND @rangoActual > 0 THEN @rangoActual  -- Para consultar bono "mantiene"
                ELSE NULL
            END AS nivel_rango_para_bono
        FROM CalculoRangoAnterior r
    ),
    BonoObtenido AS (
        SELECT 
            c.*,
            ISNULL(br.bono, 0) AS monto_bono
        FROM ComparacionRangos c
        LEFT JOIN dbo.BonoRango br ON 
            br.nivel_rango = c.nivel_rango_para_bono
            AND br.tipo_bono = c.tipo_bono
            AND DATEFROMPARTS(@añoActual, @mesActual, 1) BETWEEN br.fecha_inicio AND ISNULL(br.fecha_fin, DATEFROMPARTS(@añoActual, @mesActual, 1))
    )
    SELECT 
        ventas_mes_anterior,
        rango_mes_anterior,
        rango_actual,
        tipo_bono,
        monto_bono
    FROM BonoObtenido
);

