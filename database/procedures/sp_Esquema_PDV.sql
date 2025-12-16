CREATE PROCEDURE dbo.sp_Esquema_PDV
@año int,@mes int
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fechaPeriodo DATE = DATEFROMPARTS(@año, @mes, 1);
    DECLARE @zonalPattern VARCHAR(50) = 'TODAS';
    DECLARE @maxDateCalidad DATE;

    -- Variables de rango de fechas para optimización (usar índices)
    DECLARE @fechaInicioMes DATE = DATEFROMPARTS(@año, @mes, 1);
    DECLARE @fechaFinMes DATE = DATEADD(MONTH, 1, @fechaInicioMes); -- Primer día del mes siguiente (exclusivo)
    DECLARE @fechaInicioMesAnterior DATE;
    DECLARE @fechaFinMesAnterior DATE;

    -- Calcular fechas del mes anterior
    IF @mes > 1
    BEGIN
        SET @fechaInicioMesAnterior = DATEFROMPARTS(@año, @mes - 1, 1);
        SET @fechaFinMesAnterior = DATEFROMPARTS(@año, @mes, 1);
    END
    ELSE
    BEGIN
        SET @fechaInicioMesAnterior = DATEFROMPARTS(@año - 1, 12, 1);
        SET @fechaFinMesAnterior = DATEFROMPARTS(@año, 1, 1);
    END

    -- Obtener fecha máxima de calidad desde parámetros
    SELECT @maxDateCalidad = TRY_CAST(valor AS DATE)
    FROM dbo.parametros
    WHERE tipo = 4;

    IF @maxDateCalidad IS NULL
        SET @maxDateCalidad = EOMONTH(@fechaPeriodo);

    ;WITH PDVEntregable AS (
        SELECT DISTINCT
            e.DNI_RESPONSABLE,
            e.NOMBRE_RESPONSABLE,
            e.ZONAL,
            e.ACCION_1,
            e.ACCION_2,
            CASE
                WHEN e.RANGO IS NULL OR e.RANGO = '' THEN 0
                ELSE TRY_CAST(REPLACE(REPLACE(e.RANGO, 'RANGO ', ''), 'R', '') AS INT)
            END AS RANGO_MES_ANTERIOR,
            CASE WHEN e.ACCION_1 IN ('PDV REGULAR', 'PDV PREMIUM') OR e.ACCION_1 LIKE 'PDV PREMIUM%' THEN 2.00 ELSE 0.00 END AS PRECIO_UNI_TYPE_PDV
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e
        WHERE e.AÑO = @año AND e.MES = @mes
          AND e.ESTADO = 'ACTIVO'
    ),

    -- CTE para pre-filtrar BonoEscala (optimización: incluir todos los campos necesarios)
    BonoEscalaFiltrada AS (
        SELECT
            tipo_pdv,
            zonal_pattern,
            nivel_rango,
            rango_min,
            rango_max,
            bono,
            ratio_min,
            cantidad_calidad_min
        FROM dbo.BonoEscala
        WHERE @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo)
    ),

    -- CTE para pre-calcular MAX_VENTA y RATIO_MIN por tipo PDV (optimización: usar BonoEscalaFiltrada)
    ConfiguracionBonoAgregada AS (
        SELECT
            tipo_pdv,
            zonal_pattern,
            MAX(rango_max) AS MAX_VENTA,
            MIN(ratio_min) AS RATIO_MIN_GLOBAL
        FROM BonoEscalaFiltrada
        GROUP BY tipo_pdv, zonal_pattern
    ),

    -- CTE para calcular RATIO_MIN global (optimización: calcular una sola vez)
    RatioMinGlobal AS (
        SELECT MIN(ratio_min) AS RATIO_MIN
        FROM BonoEscalaFiltrada
    ),

    -- CTE para obtener maxVenta y ratioMin desde BonoEscala (optimizado: usa CTE pre-calculado)
    ConfiguracionBono AS (
        SELECT
            e.DNI_RESPONSABLE,
            e.ACCION_2,
            ISNULL(MAX(cba.MAX_VENTA), 0) AS MAX_VENTA,
            ISNULL(rm.RATIO_MIN, 0) AS RATIO_MIN
        FROM PDVEntregable e
        LEFT JOIN ConfiguracionBonoAgregada cba ON
            cba.tipo_pdv = CASE WHEN e.ACCION_2 LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM' ELSE e.ACCION_2 END
            AND cba.zonal_pattern = @zonalPattern
        CROSS JOIN RatioMinGlobal rm
        GROUP BY e.DNI_RESPONSABLE, e.ACCION_2, rm.RATIO_MIN
    ),

    -- CTE para calcular días únicos de ventas por responsable (equipo completo)
    DiasVentasResponsable AS (
        SELECT
            DNI_RESPONSABLE,
            COUNT(DISTINCT CAST(FECHA AS DATE)) AS DIAS_VENTAS_RESPONSABLE
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes
          AND PRODUCT_NAME = 'Prepago'
          AND DNI_RESPONSABLE IS NOT NULL
        GROUP BY DNI_RESPONSABLE
    ),

    -- CTE para calcular ventas del mes anterior
    VentasMesAnterior AS (
        SELECT
            DNI_RESPONSABLE,
            COUNT(*) AS VENTAS_MES_ANTERIOR
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMesAnterior AND FECHA < @fechaFinMesAnterior
          AND PRODUCT_NAME = 'Prepago'
          AND DNI_RESPONSABLE IS NOT NULL
        GROUP BY DNI_RESPONSABLE
    ),

    EventosCombinados AS (
        -- Ventas Prepago
        SELECT DNI_RESPONSABLE, 'VENTA' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes AND PRODUCT_NAME = 'Prepago'
        UNION ALL
        -- Pre-Portabilidades
        SELECT DNI_RESPONSABLE, 'PRE_PORTA' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes AND PRODUCT_NAME = 'Prepago' AND OPERATION_NAME='Portabilidad'
        UNION ALL
        -- Recargas
        SELECT DNI_RESPONSABLE, 'RECARGA' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE fecha >= @fechaInicioMes AND fecha < @fechaFinMes
          AND RECARGA_SI_NO = 1 AND [RECARGAS>5] = 1
          AND PRODUCTO_WEB IN ('PREPAGO M7', 'PORT PREPAGO M7')
        UNION ALL
        -- Ventas de Calidad (con fecha límite)
        SELECT DNI_RESPONSABLE, 'VENTA_CALIDAD' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE fecha >= @fechaInicioMes AND fecha < @fechaFinMes
          AND fecha <= @maxDateCalidad
          AND CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')
        UNION ALL
        -- Portabilidades Prepago
        SELECT DNI_RESPONSABLE, 'PORTA_PRE' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE fecha >= @fechaInicioMes AND fecha < @fechaFinMes
          AND DNI_RESPONSABLE IS NOT NULL
          AND PRODUCTOORIGEN = 'PREPAGO' AND PRODUCTO_WEB = 'PORT M4 NO DIR'
        UNION ALL
        -- Portabilidades Postpago
        SELECT DNI_RESPONSABLE, 'PORTA_POS' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE fecha >= @fechaInicioMes AND fecha < @fechaFinMes
          AND DNI_RESPONSABLE IS NOT NULL
          AND PRODUCTOORIGEN = 'POSTPAGO' AND PRODUCTO_WEB = 'PORT M4 NO DIR'
    ),

    -- CTE para calcular ventas prepago totales (usando SUM cantidad)
    VentasPrepagoTotales AS (
        SELECT
            DNI_RESPONSABLE,
            SUM(cantidad) AS VENTA_AVANCE_PREPAGO
        FROM dbo.tbl_venta_log
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes
          AND PRODUCT_NAME = 'Prepago'
          AND DNI_RESPONSABLE IS NOT NULL
        GROUP BY DNI_RESPONSABLE
    ),

    -- CTE para calcular ventas prepago con fecha límite de calidad
    VentasPrepagoCalidad AS (
        SELECT
            DNI_RESPONSABLE,
            SUM(cantidad) AS VENTA_PREPAGO_CALIDAD
        FROM dbo.tbl_venta_log
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes
          AND FECHA <= @maxDateCalidad
          AND PRODUCT_NAME = 'Prepago'
          AND DNI_RESPONSABLE IS NOT NULL
        GROUP BY DNI_RESPONSABLE
    ),

    MetricasAgregadas AS (
        SELECT
            p.DNI_RESPONSABLE,
            p.NOMBRE_RESPONSABLE,
            p.ZONAL,
            p.ACCION_1,
            p.ACCION_2,
            p.RANGO_MES_ANTERIOR,
            p.PRECIO_UNI_TYPE_PDV,
            -- Totales de eventos
            SUM(CASE WHEN e.TIPO_EVENTO = 'VENTA' THEN 1 ELSE 0 END) AS TOTAL_VENTAS,
            SUM(CASE WHEN e.TIPO_EVENTO = 'RECARGA' THEN 1 ELSE 0 END) AS TOTAL_RECARGAS,
            SUM(CASE WHEN e.TIPO_EVENTO = 'VENTA_CALIDAD' THEN 1 ELSE 0 END) AS TOTAL_VCALIDAD,
            SUM(CASE WHEN e.TIPO_EVENTO = 'PRE_PORTA' THEN 1 ELSE 0 END) AS PRE_PORTA,
            SUM(CASE WHEN e.TIPO_EVENTO = 'PORTA_PRE' THEN 1 ELSE 0 END) AS PORTAPRE,
            SUM(CASE WHEN e.TIPO_EVENTO = 'PORTA_POS' THEN 1 ELSE 0 END) AS PORTAPOS,
            -- Días de ventas y ventas mes anterior
            COALESCE(d.DIAS_VENTAS_RESPONSABLE, 0) AS DIAS_VENTAS_RESPONSABLE,
            COALESCE(v.VENTAS_MES_ANTERIOR, 0) AS VENTAS_MES_ANTERIOR,
            COALESCE(vpt.VENTA_AVANCE_PREPAGO, 0) AS VENTA_AVANCE_PREPAGO,
            COALESCE(vpc.VENTA_PREPAGO_CALIDAD, 0) AS VENTA_PREPAGO_CALIDAD
        FROM PDVEntregable p
        LEFT JOIN EventosCombinados e ON p.DNI_RESPONSABLE = e.DNI_RESPONSABLE
        LEFT JOIN DiasVentasResponsable d ON p.DNI_RESPONSABLE = d.DNI_RESPONSABLE
        LEFT JOIN VentasMesAnterior v ON p.DNI_RESPONSABLE = v.DNI_RESPONSABLE
        LEFT JOIN VentasPrepagoTotales vpt ON p.DNI_RESPONSABLE = vpt.DNI_RESPONSABLE
        LEFT JOIN VentasPrepagoCalidad vpc ON p.DNI_RESPONSABLE = vpc.DNI_RESPONSABLE
        GROUP BY p.DNI_RESPONSABLE,
            p.NOMBRE_RESPONSABLE,
            p.ZONAL,
            p.ACCION_1,
            p.ACCION_2,
            p.RANGO_MES_ANTERIOR,
            p.PRECIO_UNI_TYPE_PDV,
            d.DIAS_VENTAS_RESPONSABLE,
            v.VENTAS_MES_ANTERIOR,
            vpt.VENTA_AVANCE_PREPAGO,
            vpc.VENTA_PREPAGO_CALIDAD
    ),

    -- CTE para datos de Postpago
    PostpagoData AS (
        SELECT
            f.DNI_RESPONSABLE,
            COUNT(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 1 END) AS cantidadAltaPost,
            COUNT(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 END) AS cantidadPortaPostOPost,
            COUNT(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 END) AS cantidadPortaPostOPre
        FROM dbo.PDV_OUT_FUNNEL f
        INNER JOIN PDVEntregable p ON f.DNI_RESPONSABLE = p.DNI_RESPONSABLE AND f.ACCION = p.ACCION_1
        WHERE f.FECHA >= @fechaInicioMes AND f.FECHA < @fechaFinMes
          AND (
              f.PRODUCTO_WEB = 'POSTPAGO M4'
              OR (f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND f.PRODUCTOORIGEN IN ('PREPAGO', 'POSTPAGO'))
          )
        GROUP BY f.DNI_RESPONSABLE
    ),

    -- CTE para portabilidades prepago desde tbl_ventas_prepago_new
    PortaPrepagoData AS (
        SELECT
            p.DNI_RESPONSABLE,
            SUM(p.PORTA_PREPAGO) AS cantPrepagoPorta
        FROM dbo.tbl_ventas_prepago_new p
        INNER JOIN PDVEntregable e ON p.DNI_RESPONSABLE = e.DNI_RESPONSABLE
        WHERE p.FECHA >= @fechaInicioMes AND p.FECHA < @fechaFinMes
        GROUP BY p.DNI_RESPONSABLE
    ),

    -- CTE para cálculos base con límites y ratios
    CalculosBase AS (
        SELECT
            m.*,
            cb.MAX_VENTA,
            cb.RATIO_MIN,
            ISNULL(pd.cantidadAltaPost, 0) AS cantidadAltaPost,
            ISNULL(pd.cantidadPortaPostOPost, 0) AS cantidadPortaPostOPost,
            ISNULL(pd.cantidadPortaPostOPre, 0) AS cantidadPortaPostOPre,
            ISNULL(ppd.cantPrepagoPorta, 0) AS cantPrepagoPorta,
            CASE WHEN m.VENTA_AVANCE_PREPAGO > cb.MAX_VENTA THEN cb.MAX_VENTA ELSE m.VENTA_AVANCE_PREPAGO END AS VentaPrepagoLimitada,
            CASE WHEN m.VENTA_PREPAGO_CALIDAD > cb.MAX_VENTA THEN cb.MAX_VENTA ELSE m.VENTA_PREPAGO_CALIDAD END AS VentaPrepagoCalidadLimitada,
            FLOOR((CAST(m.TOTAL_RECARGAS AS DECIMAL(10,2)) / NULLIF(CAST(m.VENTA_AVANCE_PREPAGO AS DECIMAL(10,2)), 0) * 100)) AS ratio,
            FLOOR((CAST(m.TOTAL_VCALIDAD AS DECIMAL(10,2)) / NULLIF(CAST(m.VENTA_PREPAGO_CALIDAD AS DECIMAL(10,2)), 0) * 100)) AS ratioCalidad
        FROM MetricasAgregadas m
        INNER JOIN ConfiguracionBono cb ON m.DNI_RESPONSABLE = cb.DNI_RESPONSABLE
        LEFT JOIN PostpagoData pd ON m.DNI_RESPONSABLE = pd.DNI_RESPONSABLE
        LEFT JOIN PortaPrepagoData ppd ON m.DNI_RESPONSABLE = ppd.DNI_RESPONSABLE
    ),

    -- CTE para pre-calcular valores agregados de BonoEscala por tipo/zona
    BonoEscalaAgregados AS (
        SELECT
            tipo_pdv,
            zonal_pattern,
            MIN(rango_min) AS min_rango_min
        FROM BonoEscalaFiltrada
        GROUP BY tipo_pdv, zonal_pattern
    ),

    -- CTE para pre-filtrar BonoRango por fecha (optimización: evitar filtro en JOIN)
    BonoRangoFiltrado AS (
        SELECT
            nivel_rango,
            tipo_bono,
            bono
        FROM dbo.BonoRango
        WHERE @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo)
    ),

    -- CTE para calcular nivel_rango (optimizado: CROSS APPLY con CTE pre-filtrado)
    CalculosConRango AS (
        SELECT
            c.*,
            be.nivel_rango
        FROM CalculosBase c
        OUTER APPLY (
            SELECT TOP 1 nivel_rango
            FROM BonoEscalaFiltrada
            WHERE tipo_pdv = CASE WHEN c.ACCION_2 LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM' ELSE c.ACCION_2 END
              AND zonal_pattern = @zonalPattern
              AND c.VentaPrepagoLimitada >= rango_min
              AND c.VentaPrepagoLimitada <= rango_max
            ORDER BY nivel_rango DESC
        ) be
    ),

    -- CTE para calcular zonalPattern por PDV (lógica de la función)
    PDVConZonalPattern AS (
        SELECT
            c.*,
            CASE
                WHEN c.ZONAL LIKE '%LIMA SUR%' THEN '%LIMA SUR%'
                WHEN CASE WHEN c.ACCION_2 LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM' ELSE c.ACCION_2 END = 'PDV REGULAR' THEN 'TODAS'
                ELSE 'REGIONES'
            END AS zonal_pattern_calc,
            CASE WHEN c.ACCION_2 LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM' ELSE c.ACCION_2 END AS tipo_pdv_normalizado
        FROM CalculosConRango c
    ),

    -- CTE para calcular precioUniSchema (optimizado: usar OUTER APPLY en lugar de subconsultas)
    CalculosConFunciones AS (
        SELECT
            p.*,
            -- Calcular precioUniSchema según tipo PDV y zonalPattern usando OUTER APPLY
            ISNULL(be_bono.bono, 0) AS precioUniSchema,
            CASE WHEN p.nivel_rango >= 2 THEN p.VentaPrepagoLimitada ELSE 0 END AS bonoDevolucionChips,
            (CASE
                WHEN p.VentaPrepagoCalidadLimitada BETWEEN 50 AND 150 AND p.ratioCalidad >= 50 THEN 1.5
                WHEN p.VentaPrepagoCalidadLimitada BETWEEN 5 AND 49 AND p.ratioCalidad >= 50 THEN 1.0
                ELSE 0
            END) AS precioUniCalidadAdi
        FROM PDVConZonalPattern p
        OUTER APPLY (
            SELECT TOP 1 b.bono
            FROM BonoEscalaFiltrada b
            LEFT JOIN BonoEscalaAgregados ba ON
                ba.tipo_pdv = 'PDV PREMIUM' AND ba.zonal_pattern = 'REGIONES'
            OUTER APPLY (
                -- Para PDV PREMIUM REGIONES: calcular max_cantidad_calidad_min
                SELECT MAX(b3.cantidad_calidad_min) AS max_cantidad_calidad_min
                FROM BonoEscalaFiltrada b3
                WHERE b3.tipo_pdv = 'PDV PREMIUM'
                  AND b3.zonal_pattern = 'REGIONES'
                  AND p.TOTAL_VCALIDAD >= ISNULL(b3.cantidad_calidad_min, 0)
            ) max_cal
            WHERE
                -- PDV REGULAR
                (p.tipo_pdv_normalizado = 'PDV REGULAR'
                 AND b.tipo_pdv = 'PDV REGULAR'
                 AND b.zonal_pattern = p.zonal_pattern_calc
                 AND p.VentaPrepagoLimitada >= b.rango_min
                 AND p.ratio >= b.ratio_min
                 AND p.TOTAL_VCALIDAD >= ISNULL(b.cantidad_calidad_min, 0))
                OR
                -- PDV PREMIUM LIMA SUR
                (p.tipo_pdv_normalizado = 'PDV PREMIUM'
                 AND p.zonal_pattern_calc = '%LIMA SUR%'
                 AND b.tipo_pdv = 'PDV PREMIUM'
                 AND b.zonal_pattern LIKE '%LIMA SUR%'
                 AND p.VentaPrepagoLimitada >= b.rango_min
                 AND p.ratio >= b.ratio_min
                 AND p.TOTAL_VCALIDAD >= ISNULL(b.cantidad_calidad_min, 0))
                OR
                -- PDV PREMIUM REGIONES
                (p.tipo_pdv_normalizado = 'PDV PREMIUM'
                 AND p.zonal_pattern_calc = 'REGIONES'
                 AND b.tipo_pdv = 'PDV PREMIUM'
                 AND b.zonal_pattern = 'REGIONES'
                 AND p.VentaPrepagoLimitada >= ba.min_rango_min
                 AND p.TOTAL_VCALIDAD >= ISNULL(b.cantidad_calidad_min, 0)
                 AND p.ratio >= b.ratio_min)
            ORDER BY
                -- Ordenamiento según tipo
                CASE
                    -- PDV REGULAR y PDV PREMIUM LIMA SUR: mismo ordenamiento
                    WHEN p.tipo_pdv_normalizado = 'PDV REGULAR' OR
                         (p.tipo_pdv_normalizado = 'PDV PREMIUM' AND p.zonal_pattern_calc = '%LIMA SUR%') THEN
                        CASE WHEN p.VentaPrepagoLimitada <= b.rango_max THEN 0 ELSE 1 END
                    -- PDV PREMIUM REGIONES: la calidad manda
                    WHEN p.tipo_pdv_normalizado = 'PDV PREMIUM' AND p.zonal_pattern_calc = 'REGIONES' THEN
                        CASE WHEN b.cantidad_calidad_min = max_cal.max_cantidad_calidad_min THEN 1 ELSE 0 END
                    ELSE 0
                END DESC,
                -- Ordenamiento común
                CASE
                    WHEN p.tipo_pdv_normalizado = 'PDV PREMIUM' AND p.zonal_pattern_calc = 'REGIONES' THEN
                        b.cantidad_calidad_min
                    ELSE b.rango_max
                END DESC,
                b.ratio_min DESC,
                b.bono DESC
        ) be_bono
    ),

    -- CTE para calcular bono de rango (optimizado: sin función, lógica directa)
    CalculosConBonoRango AS (
        SELECT
            c.*,
            c.nivel_rango AS rango_actual,
            CASE
                WHEN c.nivel_rango > ISNULL(c.RANGO_MES_ANTERIOR, 0) THEN 'sube'
                WHEN c.nivel_rango = ISNULL(c.RANGO_MES_ANTERIOR, 0) AND c.nivel_rango > 0 THEN 'mantiene'
                ELSE NULL
            END AS tipo_bono,
            -- Calcular bono_rango: solo se paga si cumple ratio_min y hay tipo_bono válido
            CASE
                WHEN c.ratio >= c.RATIO_MIN AND c.nivel_rango > ISNULL(c.RANGO_MES_ANTERIOR, 0) THEN ISNULL(br.bono, 0)
                WHEN c.ratio >= c.RATIO_MIN AND c.nivel_rango = ISNULL(c.RANGO_MES_ANTERIOR, 0) AND c.nivel_rango > 0 THEN ISNULL(br.bono, 0)
                ELSE 0
            END AS bono_rango
        FROM CalculosConFunciones c
        LEFT JOIN BonoRangoFiltrado br ON
            br.nivel_rango = ISNULL(c.RANGO_MES_ANTERIOR, 0)
            AND (
                (c.nivel_rango > ISNULL(c.RANGO_MES_ANTERIOR, 0) AND br.tipo_bono = 'sube')
                OR
                (c.nivel_rango = ISNULL(c.RANGO_MES_ANTERIOR, 0) AND c.nivel_rango > 0 AND br.tipo_bono = 'mantiene')
            )
    )

    SELECT
        m.DNI_RESPONSABLE,
        m.NOMBRE_RESPONSABLE,
        m.ZONAL,
        m.ACCION_1,
        m.ACCION_2,
        m.RANGO_MES_ANTERIOR,
        -- Métricas totales
        m.TOTAL_VENTAS,
        m.TOTAL_RECARGAS,
        m.TOTAL_VCALIDAD,
        m.PRE_PORTA,
        m.PORTAPRE,
        m.PORTAPOS,
        -- Métricas adicionales
        m.DIAS_VENTAS_RESPONSABLE,
        m.VENTAS_MES_ANTERIOR,
        COALESCE((CAST(m.TOTAL_RECARGAS AS DECIMAL(10,2)) * 100) / NULLIF(m.VENTA_AVANCE_PREPAGO, 0), 0) AS RATIO_EQUIPO,
        -- Datos de postpago y portabilidades
        c.cantidadAltaPost,
        c.cantidadPortaPostOPost,
        c.cantidadPortaPostOPre,
        c.cantPrepagoPorta,
        -- Cálculos de bonos
        c.VentaPrepagoLimitada AS bonoChips,
        c.precioUniSchema AS BONO_UNITARIO_EQUIPO,
        c.bonoDevolucionChips,
        c.precioUniCalidadAdi,
        (c.TOTAL_VCALIDAD * c.precioUniCalidadAdi) AS bonoCalidad,
        (c.TOTAL_RECARGAS * m.PRECIO_UNI_TYPE_PDV) AS bonoRecargaPre,
        (c.cantPrepagoPorta * 4) AS bonoPortaPre,
        (c.cantidadPortaPostOPost * 35) AS bonoPortaPostOPost,
        (c.cantidadPortaPostOPre * 20) AS bonoPortaPostOPre,
        -- Bono de rango
        c.nivel_rango,
        c.RANGO_MES_ANTERIOR AS rango_mes_anterior_calc,
        c.rango_actual,
        c.tipo_bono,
        c.bono_rango,
        c.RATIO_MIN AS ratio_min_requerido,
        -- Totales de bonos
        (
            ISNULL((c.precioUniSchema * c.VentaPrepagoLimitada), 0) +
            ISNULL((c.TOTAL_RECARGAS * m.PRECIO_UNI_TYPE_PDV), 0) +
            ISNULL((c.cantPrepagoPorta * 4), 0) +
            ISNULL((c.cantidadPortaPostOPost * 35), 0) +
            ISNULL((c.cantidadPortaPostOPre * 20), 0) +
            ISNULL((c.TOTAL_VCALIDAD * c.precioUniCalidadAdi), 0) +
            ISNULL(c.bono_rango, 0)
        ) AS bonoTotalEfectivo,
        (
            ISNULL((c.precioUniSchema * c.VentaPrepagoLimitada), 0) +
            ISNULL((c.TOTAL_RECARGAS * m.PRECIO_UNI_TYPE_PDV), 0) +
            ISNULL((c.cantPrepagoPorta * 4), 0) +
            ISNULL((c.cantidadPortaPostOPost * 35), 0) +
            ISNULL((c.cantidadPortaPostOPre * 20), 0) +
            ISNULL((c.TOTAL_VCALIDAD * c.precioUniCalidadAdi), 0) +
            ISNULL(c.bonoDevolucionChips, 0) +
            ISNULL(c.bono_rango, 0)
        ) AS bonoTotal
    FROM MetricasAgregadas m
    INNER JOIN CalculosConBonoRango c ON m.DNI_RESPONSABLE = c.DNI_RESPONSABLE
    ORDER BY m.ZONAL, m.ACCION_1, m.DNI_RESPONSABLE;
END;

