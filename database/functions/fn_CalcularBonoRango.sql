-- Función para calcular el bono por rango (sube/mantiene)
-- Retorna una tabla con: rango_mes_anterior, rango_actual, tipo_bono, bono_rango
-- Alta cohesión: toda la lógica de cálculo de bono por rango está aquí
-- Bajo acoplamiento: no depende de lógica específica del SP, solo recibe parámetros
-- El rango del mes anterior viene directamente de PDV_OUT_ENTREGABLE.RANGO
-- NOVIEMBRE 2025: Se valida ratio_min desde BonoEscala para pagar el bono
-- IMPORTANTE: El bono se calcula en base al RANGO INICIAL (mes anterior), no al rango al que subió
-- Ejemplo: Si rango inicial es R3 y sube a R7, se paga el bono de R3 "sube" (S/ 25), no el de R7

CREATE FUNCTION dbo.fn_CalcularBonoRango(
    @rangoMesAnterior INT,  -- Rango del mes anterior desde PDV_OUT_ENTREGABLE
    @rangoActual INT,       -- Rango actual calculado en base a ventas
    @añoActual INT,         -- Año actual para consultar BonoRango
    @mesActual INT,         -- Mes actual para consultar BonoRango
    @ratio DECIMAL(5,2)     -- Ratio de recargas para validar ratio_min
)
RETURNS TABLE
AS
RETURN
(
    -- Obtener ratio_min del período desde BonoEscala (es el mismo para todos los rangos)
    WITH RatioMinimo AS (
        SELECT
            ISNULL(MIN(ratio_min), 0) AS ratio_min_periodo
        FROM dbo.BonoEscala
        WHERE DATEFROMPARTS(@añoActual, @mesActual, 1) BETWEEN fecha_inicio AND ISNULL(fecha_fin, DATEFROMPARTS(@añoActual, @mesActual, 1))
    ),
    ComparacionRangos AS (
        SELECT
            ISNULL(@rangoMesAnterior, 0) AS rango_mes_anterior,
            @rangoActual AS rango_actual,
            CASE
                WHEN @rangoActual > ISNULL(@rangoMesAnterior, 0) THEN 'sube'
                WHEN @rangoActual = ISNULL(@rangoMesAnterior, 0) AND @rangoActual > 0 THEN 'mantiene'
                ELSE NULL
            END AS tipo_bono,
            CASE
                WHEN @rangoActual > ISNULL(@rangoMesAnterior, 0) THEN @rangoMesAnterior  -- Para consultar bono "sube" - usa rango inicial
                WHEN @rangoActual = ISNULL(@rangoMesAnterior, 0) AND @rangoActual > 0 THEN @rangoMesAnterior  -- Para consultar bono "mantiene" - usa rango inicial
                ELSE NULL
            END AS nivel_rango_para_bono,
            rm.ratio_min_periodo
        FROM RatioMinimo rm
    ),
    BonoObtenido AS (
        SELECT
            c.*,
            -- NOVIEMBRE 2025: Solo pagar bono_rango si cumple con ratio_min
            CASE
                WHEN c.tipo_bono IS NOT NULL AND @ratio >= c.ratio_min_periodo THEN ISNULL(br.bono, 0)
                ELSE 0
            END AS bono_rango
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

