-- Función para calcular el bono por rango (sube/mantiene)
-- Retorna una tabla con: rango_mes_anterior, rango_actual, tipo_bono, bono_rango
-- Alta cohesión: toda la lógica de cálculo de bono por rango está aquí
-- Bajo acoplamiento: no depende de lógica específica del SP, solo recibe parámetros
-- El rango del mes anterior viene directamente de PDV_OUT_ENTREGABLE.RANGO

CREATE FUNCTION dbo.fn_CalcularBonoRango(
    @rangoMesAnterior INT,  -- Rango del mes anterior desde PDV_OUT_ENTREGABLE
    @rangoActual INT,       -- Rango actual calculado en base a ventas
    @añoActual INT,         -- Año actual para consultar BonoRango
    @mesActual INT          -- Mes actual para consultar BonoRango
)
RETURNS TABLE
AS
RETURN
(
    WITH ComparacionRangos AS (
        SELECT 
            ISNULL(@rangoMesAnterior, 0) AS rango_mes_anterior,
            @rangoActual AS rango_actual,
            CASE 
                WHEN @rangoActual > ISNULL(@rangoMesAnterior, 0) THEN 'sube'
                WHEN @rangoActual = ISNULL(@rangoMesAnterior, 0) AND @rangoActual > 0 THEN 'mantiene'
                ELSE NULL
            END AS tipo_bono,
            CASE 
                WHEN @rangoActual > ISNULL(@rangoMesAnterior, 0) THEN @rangoActual  -- Para consultar bono "sube"
                WHEN @rangoActual = ISNULL(@rangoMesAnterior, 0) AND @rangoActual > 0 THEN @rangoActual  -- Para consultar bono "mantiene"
                ELSE NULL
            END AS nivel_rango_para_bono
    ),
    BonoObtenido AS (
        SELECT 
            c.*,
            ISNULL(br.bono, 0) AS bono_rango
        FROM ComparacionRangos c
        LEFT JOIN dbo.BonoRango br ON 
            br.nivel_rango = c.nivel_rango_para_bono
            AND br.tipo_bono = c.tipo_bono
            AND DATEFROMPARTS(@añoActual, @mesActual, 1) BETWEEN br.fecha_inicio AND ISNULL(br.fecha_fin, DATEFROMPARTS(@añoActual, @mesActual, 1))
    )
    SELECT 
        rango_mes_anterior,
        rango_actual,
        tipo_bono,
        bono_rango
    FROM BonoObtenido
);

