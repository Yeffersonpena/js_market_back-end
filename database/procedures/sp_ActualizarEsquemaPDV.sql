-- SP único para actualizar todo el esquema PDV
-- Calcula métricas y bonos usando tablas temporales, luego inserta directamente en RESUMEN
-- Optimizado: evita múltiples UNION ALL, pre-filtra BonoEscala, usa tablas temporales
CREATE PROCEDURE dbo.sp_ActualizarEsquemaPDV
    @año INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @fechaPeriodo DATE = DATEFROMPARTS(@año, @mes, 1);
    DECLARE @zonalPattern VARCHAR(50) = 'TODAS';
    DECLARE @maxDateCalidad DATE;

    -- Variables de rango de fechas para optimización
    DECLARE @fechaInicioMes DATE = DATEFROMPARTS(@año, @mes, 1);
    DECLARE @fechaFinMes DATE = DATEADD(MONTH, 1, @fechaInicioMes);
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

    -- Obtener fecha máxima de calidad
    SELECT @maxDateCalidad = TRY_CAST(valor AS DATE)
    FROM dbo.parametros
    WHERE tipo = 4;

    IF @maxDateCalidad IS NULL
        SET @maxDateCalidad = EOMONTH(@fechaPeriodo);

    -- ============================================
    -- VALIDACIÓN: Fecha máxima común entre VentasLog y Funnel
    -- ============================================
    -- PROBLEMA: VentasLog y PDV_OUT_FUNNEL pueden tener datos hasta fechas diferentes.
    --          Si VentasLog tiene datos hasta el día 28 y Funnel hasta el día 26,
    --          los ratios se calculan incorrectamente (recargas hasta día 26 / ventas hasta día 28).
    -- SOLUCIÓN: Validar que ambas fuentes tengan datos y usar la fecha mínima entre ambas
    --          (fecha máxima común) para garantizar que todos los cálculos usen el mismo período.
    -- REGLA: Ambas fuentes DEBEN tener datos. Si alguna falta, el SP termina con error.
    --        Si ambas tienen datos, se usa la fecha mínima entre las máximas de cada fuente.

    DECLARE @maxFechaVentasLog DATE;
    DECLARE @maxFechaFunnel DATE;
    DECLARE @fechaMaximaComun DATE;
    DECLARE @maxFechaVentasLogStr VARCHAR(20);
    DECLARE @maxFechaFunnelStr VARCHAR(20);

    -- Obtener fecha máxima en VentasLog para el período (solo Prepago, que es lo que usamos)
    SELECT @maxFechaVentasLog = MAX(FECHA)
    FROM PORTAL_COMERCIAL.dbo.VentasLog
    WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes
      AND PRODUCT_NAME = 'Prepago'
      AND VALOR_DNI_RESPONSABLE IS NOT NULL;

    -- Obtener fecha máxima en PDV_OUT_FUNNEL para el período
    SELECT @maxFechaFunnel = MAX(fecha)
    FROM dbo.PDV_OUT_FUNNEL
    WHERE fecha >= @fechaInicioMes AND fecha < @fechaFinMes;

    -- Validar que ambas fuentes tengan datos (REQUISITO ESTRICTO)
    IF @maxFechaVentasLog IS NULL OR @maxFechaFunnel IS NULL
    BEGIN
        -- Convertir fechas a string para el mensaje de error
        SET @maxFechaVentasLogStr = CASE WHEN @maxFechaVentasLog IS NULL THEN 'NULL' ELSE CONVERT(VARCHAR(20), @maxFechaVentasLog, 120) END;
        SET @maxFechaFunnelStr = CASE WHEN @maxFechaFunnel IS NULL THEN 'NULL' ELSE CONVERT(VARCHAR(20), @maxFechaFunnel, 120) END;

        RAISERROR('Error: Una o ambas fuentes (VentasLog/Funnel) no tienen datos para el período %d/%d. VentasLog máximo: %s, Funnel máximo: %s',
                  16, 1, @mes, @año, @maxFechaVentasLogStr, @maxFechaFunnelStr);
        RETURN;
    END;

    -- Usar la fecha mínima entre ambas (fecha máxima común)
    -- Ejemplo: VentasLog máximo = 28, Funnel máximo = 26 → usar 26
    SET @fechaMaximaComun = CASE
        WHEN @maxFechaVentasLog < @maxFechaFunnel THEN @maxFechaVentasLog
        ELSE @maxFechaFunnel
    END;

    -- A partir de aquí, @fechaMaximaComun se usa como límite superior en TODAS las consultas
    -- de VentasLog y PDV_OUT_FUNNEL para garantizar consistencia en los cálculos.

    -- ============================================
    -- ETAPA 1: CALCULAR MÉTRICAS EN TABLA TEMPORAL
    -- ============================================

    -- Tabla temporal para eventos agregados (evita UNION ALL)
    CREATE TABLE #EventosAgregados (
        DNI_RESPONSABLE INT,
        PRE_PORTA INT DEFAULT 0,
        TOTAL_RECARGAS INT DEFAULT 0,
        TOTAL_VCALIDAD INT DEFAULT 0,
        PORTAPRE INT DEFAULT 0,
        PORTAPOS INT DEFAULT 0,
        PRIMARY KEY (DNI_RESPONSABLE)
    );

    -- Actualizar pre-portabilidades
    -- CAMBIO: Agregado filtro de fecha máxima común para sincronizar con Funnel
    MERGE #EventosAgregados AS destino
    USING (
        SELECT VALOR_DNI_RESPONSABLE AS DNI_RESPONSABLE, COUNT(*) AS cnt
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes
          AND FECHA <= @fechaMaximaComun  -- NUEVO: Limitar a fecha máxima común
          AND PRODUCT_NAME = 'Prepago' AND OPERATION_NAME = 'Portabilidad'
          AND VALOR_DNI_RESPONSABLE IS NOT NULL
        GROUP BY VALOR_DNI_RESPONSABLE
    ) AS origen
    ON destino.DNI_RESPONSABLE = origen.DNI_RESPONSABLE
    WHEN MATCHED THEN UPDATE SET destino.PRE_PORTA = origen.cnt
    WHEN NOT MATCHED THEN INSERT (DNI_RESPONSABLE, PRE_PORTA) VALUES (origen.DNI_RESPONSABLE, origen.cnt);

    -- Actualizar recargas
    -- CAMBIO: Agregado filtro de fecha máxima común para sincronizar con VentasLog
    MERGE #EventosAgregados AS destino
    USING (
        SELECT e4.DNI_RESPONSABLE, COUNT(*) AS cnt
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e4
        INNER JOIN dbo.PDV_OUT_FUNNEL f ON f.DNI_RESPONSABLE = e4.DNI_RESPONSABLE AND f.ACCION = e4.ACCION_1
        WHERE e4.AÑO = @año AND e4.MES = @mes AND e4.ESTADO = 'ACTIVO'
          AND f.fecha >= @fechaInicioMes AND f.fecha < @fechaFinMes
          AND f.fecha <= @fechaMaximaComun  -- NUEVO: Limitar a fecha máxima común
          AND f.RECARGA_SI_NO = 1 AND f.[RECARGAS>5] = 1
          AND f.PRODUCTO_WEB IN ('PREPAGO M7', 'PORT PREPAGO M7')
        GROUP BY e4.DNI_RESPONSABLE
    ) AS origen
    ON destino.DNI_RESPONSABLE = origen.DNI_RESPONSABLE
    WHEN MATCHED THEN UPDATE SET destino.TOTAL_RECARGAS = origen.cnt
    WHEN NOT MATCHED THEN INSERT (DNI_RESPONSABLE, TOTAL_RECARGAS) VALUES (origen.DNI_RESPONSABLE, origen.cnt);

    -- Actualizar ventas de calidad
    -- CAMBIO: Agregado filtro de fecha máxima común (además de @maxDateCalidad)
    MERGE #EventosAgregados AS destino
    USING (
        SELECT e4.DNI_RESPONSABLE, COUNT(*) AS cnt
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e4
        INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL f ON f.DNI_RESPONSABLE = e4.DNI_RESPONSABLE AND f.ACCION = e4.ACCION_1
        WHERE e4.AÑO = @año AND e4.MES = @mes AND e4.ESTADO = 'ACTIVO'
          AND f.fecha >= @fechaInicioMes AND f.fecha < @fechaFinMes
          AND f.fecha <= @fechaMaximaComun  -- NUEVO: Limitar a fecha máxima común
          AND f.fecha <= @maxDateCalidad    -- Mantener lógica de calidad existente
          AND f.CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')
        GROUP BY e4.DNI_RESPONSABLE
    ) AS origen
    ON destino.DNI_RESPONSABLE = origen.DNI_RESPONSABLE
    WHEN MATCHED THEN UPDATE SET destino.TOTAL_VCALIDAD = origen.cnt
    WHEN NOT MATCHED THEN INSERT (DNI_RESPONSABLE, TOTAL_VCALIDAD) VALUES (origen.DNI_RESPONSABLE, origen.cnt);

    -- Actualizar portabilidades prepago
    -- CAMBIO: Agregado filtro de fecha máxima común para sincronizar con VentasLog
    MERGE #EventosAgregados AS destino
    USING (
        SELECT e4.DNI_RESPONSABLE, COUNT(*) AS cnt
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e4
        INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL f ON f.DNI_RESPONSABLE = e4.DNI_RESPONSABLE AND f.ACCION = e4.ACCION_1
        WHERE e4.AÑO = @año AND e4.MES = @mes AND e4.ESTADO = 'ACTIVO'
          AND f.fecha >= @fechaInicioMes AND f.fecha < @fechaFinMes
          AND f.fecha <= @fechaMaximaComun  -- NUEVO: Limitar a fecha máxima común
          AND f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR'
        GROUP BY e4.DNI_RESPONSABLE
    ) AS origen
    ON destino.DNI_RESPONSABLE = origen.DNI_RESPONSABLE
    WHEN MATCHED THEN UPDATE SET destino.PORTAPRE = origen.cnt
    WHEN NOT MATCHED THEN INSERT (DNI_RESPONSABLE, PORTAPRE) VALUES (origen.DNI_RESPONSABLE, origen.cnt);

    -- Actualizar portabilidades postpago
    -- CAMBIO: Agregado filtro de fecha máxima común para sincronizar con VentasLog
    MERGE #EventosAgregados AS destino
    USING (
        SELECT e4.DNI_RESPONSABLE, COUNT(*) AS cnt
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e4
        INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL f ON f.DNI_RESPONSABLE = e4.DNI_RESPONSABLE AND f.ACCION = e4.ACCION_1
        WHERE e4.AÑO = @año AND e4.MES = @mes AND e4.ESTADO = 'ACTIVO'
          AND f.fecha >= @fechaInicioMes AND f.fecha < @fechaFinMes
          AND f.fecha <= @fechaMaximaComun  -- NUEVO: Limitar a fecha máxima común
          AND f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR'
        GROUP BY e4.DNI_RESPONSABLE
    ) AS origen
    ON destino.DNI_RESPONSABLE = origen.DNI_RESPONSABLE
    WHEN MATCHED THEN UPDATE SET destino.PORTAPOS = origen.cnt
    WHEN NOT MATCHED THEN INSERT (DNI_RESPONSABLE, PORTAPOS) VALUES (origen.DNI_RESPONSABLE, origen.cnt);

    -- Tabla temporal con todas las métricas calculadas
    CREATE TABLE #MetricasCalculadas (
        DNI_RESPONSABLE INT PRIMARY KEY,
        TOTAL_RECARGAS INT DEFAULT 0,
        TOTAL_VCALIDAD INT DEFAULT 0,
        PRE_PORTA INT DEFAULT 0,
        PORTAPRE INT DEFAULT 0,
        PORTAPOS INT DEFAULT 0,
        DIAS_VENTAS_RESPONSABLE INT DEFAULT 0,
        VENTAS_MES_ANTERIOR INT DEFAULT 0,
        VENTA_AVANCE_PREPAGO INT DEFAULT 0,
        VENTA_PREPAGO_CALIDAD INT DEFAULT 0,
        cantidadAltaPost INT DEFAULT 0,
        cantidadPortaPostOPost INT DEFAULT 0,
        cantidadPortaPostOPre INT DEFAULT 0,
        cantPrepagoPorta INT DEFAULT 0,
        VentaPrepagoLimitada INT DEFAULT 0,
        VentaPrepagoCalidadLimitada INT DEFAULT 0,
        ratio DECIMAL(10,2) DEFAULT 0,
        ratioCalidad DECIMAL(10,2) DEFAULT 0,
        nivel_rango INT DEFAULT 0,
        MAX_VENTA INT DEFAULT 0,
        RATIO_MIN DECIMAL(10,2) DEFAULT 0
    );

    -- Insertar métricas base
    INSERT INTO #MetricasCalculadas (
        DNI_RESPONSABLE, TOTAL_RECARGAS, TOTAL_VCALIDAD, PRE_PORTA, PORTAPRE, PORTAPOS,
        DIAS_VENTAS_RESPONSABLE, VENTAS_MES_ANTERIOR, VENTA_AVANCE_PREPAGO, VENTA_PREPAGO_CALIDAD,
        cantidadAltaPost, cantidadPortaPostOPost, cantidadPortaPostOPre, cantPrepagoPorta
    )
    SELECT
        e.DNI_RESPONSABLE,
        ISNULL(ev.TOTAL_RECARGAS, 0) AS TOTAL_RECARGAS,
        ISNULL(ev.TOTAL_VCALIDAD, 0) AS TOTAL_VCALIDAD,
        ISNULL(ev.PRE_PORTA, 0) AS PRE_PORTA,
        ISNULL(ev.PORTAPRE, 0) AS PORTAPRE,
        ISNULL(ev.PORTAPOS, 0) AS PORTAPOS,
        ISNULL(d.DIAS_VENTAS_RESPONSABLE, 0) AS DIAS_VENTAS_RESPONSABLE,
        ISNULL(v.VENTAS_MES_ANTERIOR, 0) AS VENTAS_MES_ANTERIOR,
        ISNULL(vpt.VENTA_AVANCE_PREPAGO, 0) AS VENTA_AVANCE_PREPAGO,
        ISNULL(vpc.VENTA_PREPAGO_CALIDAD, 0) AS VENTA_PREPAGO_CALIDAD,
        ISNULL(pd.cantidadAltaPost, 0) AS cantidadAltaPost,
        ISNULL(pd.cantidadPortaPostOPost, 0) AS cantidadPortaPostOPost,
        ISNULL(pd.cantidadPortaPostOPre, 0) AS cantidadPortaPostOPre,
        ISNULL(ppd.cantPrepagoPorta, 0) AS cantPrepagoPorta
    FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e
    LEFT JOIN #EventosAgregados ev ON e.DNI_RESPONSABLE = ev.DNI_RESPONSABLE
    LEFT JOIN (
        -- CAMBIO: Agregado filtro de fecha máxima común para sincronizar con Funnel
        SELECT VALOR_DNI_RESPONSABLE AS DNI_RESPONSABLE, COUNT(DISTINCT CAST(FECHA AS DATE)) AS DIAS_VENTAS_RESPONSABLE
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes
          AND FECHA <= @fechaMaximaComun  -- NUEVO: Limitar a fecha máxima común
          AND PRODUCT_NAME = 'Prepago'
          AND VALOR_DNI_RESPONSABLE IS NOT NULL
        GROUP BY VALOR_DNI_RESPONSABLE
    ) d ON e.DNI_RESPONSABLE = d.DNI_RESPONSABLE
    LEFT JOIN (
        SELECT VALOR_DNI_RESPONSABLE AS DNI_RESPONSABLE, COUNT(*) AS VENTAS_MES_ANTERIOR
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMesAnterior AND FECHA < @fechaFinMesAnterior
          AND PRODUCT_NAME = 'Prepago'
          AND VALOR_DNI_RESPONSABLE IS NOT NULL
        GROUP BY VALOR_DNI_RESPONSABLE
    ) v ON e.DNI_RESPONSABLE = v.DNI_RESPONSABLE
    LEFT JOIN (
        -- CAMBIO: Agregado filtro de fecha máxima común para sincronizar con Funnel
        -- IMPORTANTE: Esta métrica se usa en el cálculo de ratio = (TOTAL_RECARGAS / VENTA_AVANCE_PREPAGO)
        SELECT VALOR_DNI_RESPONSABLE AS DNI_RESPONSABLE, COUNT(*) AS VENTA_AVANCE_PREPAGO
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes
          AND FECHA <= @fechaMaximaComun  -- NUEVO: Limitar a fecha máxima común
          AND PRODUCT_NAME = 'Prepago'
          AND VALOR_DNI_RESPONSABLE IS NOT NULL
        GROUP BY VALOR_DNI_RESPONSABLE
    ) vpt ON e.DNI_RESPONSABLE = vpt.DNI_RESPONSABLE
    LEFT JOIN (
        -- CAMBIO: Agregado filtro de fecha máxima común (además de @maxDateCalidad)
        -- IMPORTANTE: Esta métrica se usa en el cálculo de ratioCalidad = (TOTAL_VCALIDAD / VENTA_PREPAGO_CALIDAD)
        SELECT VALOR_DNI_RESPONSABLE AS DNI_RESPONSABLE, COUNT(*) AS VENTA_PREPAGO_CALIDAD
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE FECHA >= @fechaInicioMes AND FECHA < @fechaFinMes
          AND FECHA <= @fechaMaximaComun  -- NUEVO: Limitar a fecha máxima común
          AND FECHA <= @maxDateCalidad    -- Mantener lógica de calidad existente
          AND PRODUCT_NAME = 'Prepago'
          AND VALOR_DNI_RESPONSABLE IS NOT NULL
        GROUP BY VALOR_DNI_RESPONSABLE
    ) vpc ON e.DNI_RESPONSABLE = vpc.DNI_RESPONSABLE
    LEFT JOIN (
        -- CAMBIO: Agregado filtro de fecha máxima común para sincronizar con VentasLog
        SELECT
            e3.DNI_RESPONSABLE,
            COUNT(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 1 END) AS cantidadAltaPost,
            COUNT(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 END) AS cantidadPortaPostOPost,
            COUNT(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 END) AS cantidadPortaPostOPre
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e3
        INNER JOIN dbo.PDV_OUT_FUNNEL f ON f.DNI_RESPONSABLE = e3.DNI_RESPONSABLE AND f.ACCION = e3.ACCION_1
        WHERE e3.AÑO = @año AND e3.MES = @mes AND e3.ESTADO = 'ACTIVO'
          AND f.FECHA >= @fechaInicioMes AND f.FECHA < @fechaFinMes
          AND f.FECHA <= @fechaMaximaComun  -- NUEVO: Limitar a fecha máxima común
          AND (
              f.PRODUCTO_WEB = 'POSTPAGO M4'
              OR (f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND f.PRODUCTOORIGEN IN ('PREPAGO', 'POSTPAGO'))
          )
        GROUP BY e3.DNI_RESPONSABLE
    ) pd ON e.DNI_RESPONSABLE = pd.DNI_RESPONSABLE
    LEFT JOIN (
        SELECT p.DNI_RESPONSABLE, SUM(p.PORTA_PREPAGO) AS cantPrepagoPorta
        FROM dbo.tbl_ventas_prepago_new p
        INNER JOIN PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e2 ON p.DNI_RESPONSABLE = e2.DNI_RESPONSABLE
        WHERE p.FECHA >= @fechaInicioMes AND p.FECHA < @fechaFinMes
          AND e2.AÑO = @año AND e2.MES = @mes
        GROUP BY p.DNI_RESPONSABLE
    ) ppd ON e.DNI_RESPONSABLE = ppd.DNI_RESPONSABLE
    WHERE e.AÑO = @año AND e.MES = @mes AND e.ESTADO = 'ACTIVO';

    -- Calcular ratios, límites y nivel_rango (todos los PDV se tratan igual como PDV REGULAR)
    DECLARE @MAX_VENTA_GLOBAL INT;
    DECLARE @RATIO_MIN_GLOBAL DECIMAL(10,2);

    SELECT @MAX_VENTA_GLOBAL = ISNULL(MAX(rango_max), 0)
    FROM dbo.BonoEscala
    WHERE tipo_pdv = 'PDV REGULAR'
      AND zonal_pattern = @zonalPattern
      AND @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo);

    SELECT @RATIO_MIN_GLOBAL = ISNULL(MIN(ratio_min), 0)
    FROM dbo.BonoEscala
    WHERE @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo);

    -- CRÍTICO: Actualizar TODOS los registros de #MetricasCalculadas, no solo los que tienen coincidencias
    -- Usar UPDATE directo con subconsultas para garantizar que todos los DNI se actualicen
    UPDATE m
    SET
        ratio = CASE
            WHEN m.VENTA_AVANCE_PREPAGO > 0 THEN FLOOR((CAST(m.TOTAL_RECARGAS AS DECIMAL(10,2)) / CAST(m.VENTA_AVANCE_PREPAGO AS DECIMAL(10,2)) * 100))
            ELSE 0
        END,
        ratioCalidad = CASE
            WHEN m.VENTA_PREPAGO_CALIDAD > 0 THEN FLOOR((CAST(m.TOTAL_VCALIDAD AS DECIMAL(10,2)) / CAST(m.VENTA_PREPAGO_CALIDAD AS DECIMAL(10,2)) * 100))
            ELSE 0
        END,
        VentaPrepagoLimitada = CASE
            -- Validación R9*: Si está en R9 (150-250) pero ratioCalidad < 45%, limitar a R8 (149)
            WHEN m.VENTA_AVANCE_PREPAGO >= 150
                 AND m.VENTA_AVANCE_PREPAGO <= 250
                 AND (CASE WHEN m.VENTA_PREPAGO_CALIDAD > 0 THEN FLOOR((CAST(m.TOTAL_VCALIDAD AS DECIMAL(10,2)) / CAST(m.VENTA_PREPAGO_CALIDAD AS DECIMAL(10,2)) * 100)) ELSE 0 END) < 45
                 THEN 149
            -- Si excede el máximo global, limitar al máximo
            WHEN m.VENTA_AVANCE_PREPAGO > @MAX_VENTA_GLOBAL THEN @MAX_VENTA_GLOBAL
            -- Caso normal
            ELSE m.VENTA_AVANCE_PREPAGO
        END,
        VentaPrepagoCalidadLimitada = CASE WHEN m.VENTA_PREPAGO_CALIDAD > @MAX_VENTA_GLOBAL THEN @MAX_VENTA_GLOBAL ELSE m.VENTA_PREPAGO_CALIDAD END,
        nivel_rango = ISNULL((
            SELECT TOP 1 be.nivel_rango
            FROM dbo.BonoEscala be
            WHERE tipo_pdv = 'PDV REGULAR'
              AND zonal_pattern = @zonalPattern
              AND @fechaPeriodo BETWEEN be.fecha_inicio AND ISNULL(be.fecha_fin, @fechaPeriodo)
              AND (CASE WHEN m.VENTA_AVANCE_PREPAGO > @MAX_VENTA_GLOBAL THEN @MAX_VENTA_GLOBAL ELSE m.VENTA_AVANCE_PREPAGO END) >= be.rango_min
              AND (CASE WHEN m.VENTA_AVANCE_PREPAGO > @MAX_VENTA_GLOBAL THEN @MAX_VENTA_GLOBAL ELSE m.VENTA_AVANCE_PREPAGO END) <= be.rango_max
            ORDER BY be.nivel_rango DESC
        ), 0),
        MAX_VENTA = @MAX_VENTA_GLOBAL,
        RATIO_MIN = @RATIO_MIN_GLOBAL
    FROM #MetricasCalculadas m;

    DROP TABLE #EventosAgregados;

    -- ============================================
    -- ETAPA 2: CALCULAR BONOS EN TABLA TEMPORAL
    -- ============================================

    -- Pre-filtrar BonoEscala solo para PDV REGULAR con zonal_pattern = 'TODAS'
    CREATE TABLE #BonoEscalaFiltrada (
        rango_min INT,
        rango_max INT,
        bono DECIMAL(10,2),
        ratio_min DECIMAL(10,2),
        cantidad_calidad_min INT,
        nivel_rango INT,
        INDEX IX_rango (rango_min, rango_max),
        INDEX IX_calidad (cantidad_calidad_min)
    );

    INSERT INTO #BonoEscalaFiltrada
    SELECT rango_min, rango_max, bono, ratio_min, cantidad_calidad_min, nivel_rango
    FROM dbo.BonoEscala
    WHERE tipo_pdv = 'PDV REGULAR'
      AND zonal_pattern = @zonalPattern
      AND @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo);

    -- Tabla temporal con todos los bonos calculados
    CREATE TABLE #BonosCalculados (
        DNI_RESPONSABLE INT PRIMARY KEY,
        BONO_UNITARIO_EQUIPO DECIMAL(10,2) DEFAULT 0,
        bonoDevolucionChips INT DEFAULT 0,
        precioUniCalidadAdi DECIMAL(10,2) DEFAULT 0,
        bonoCalidad DECIMAL(10,2) DEFAULT 0,
        bonoRecargaPre DECIMAL(10,2) DEFAULT 0,
        bonoPortaPre DECIMAL(10,2) DEFAULT 0,
        bonoPortaPostOPost DECIMAL(10,2) DEFAULT 0,
        bonoPortaPostOPre DECIMAL(10,2) DEFAULT 0,
        rango_actual INT DEFAULT 0,
        tipo_bono NVARCHAR(20) NULL,
        bono_rango DECIMAL(10,2) DEFAULT 0,
        bonoTotalEfectivo DECIMAL(10,2) DEFAULT 0,
        bonoTotal DECIMAL(10,2) DEFAULT 0
    );

    -- Calcular bonos unitarios (todos los PDV se tratan igual como PDV REGULAR)
    INSERT INTO #BonosCalculados (
        DNI_RESPONSABLE, BONO_UNITARIO_EQUIPO, bonoDevolucionChips, precioUniCalidadAdi
    )
    SELECT
        m.DNI_RESPONSABLE,
        ISNULL((
            SELECT TOP 1 b.bono
            FROM #BonoEscalaFiltrada b
            WHERE m.VentaPrepagoLimitada >= b.rango_min
              AND m.ratio >= b.ratio_min
              AND m.TOTAL_VCALIDAD >= ISNULL(b.cantidad_calidad_min, 0)
            ORDER BY
                CASE WHEN m.VentaPrepagoLimitada <= b.rango_max THEN 0 ELSE 1 END,
                b.rango_max DESC,
                b.ratio_min DESC,
                b.bono DESC
        ), 0) AS BONO_UNITARIO_EQUIPO,
        CASE WHEN m.nivel_rango >= 2 THEN m.VentaPrepagoLimitada ELSE 0 END AS bonoDevolucionChips,
        CASE
            -- R5-R9 (ventas 40-250): S/ 1.5 si ratioCalidad >= 50%
            WHEN m.VentaPrepagoCalidadLimitada >= 40 AND m.ratioCalidad >= 50 THEN 1.5
            -- R1-R4 (ventas 5-39): S/ 1.0 si ratioCalidad >= 50%
            WHEN m.VentaPrepagoCalidadLimitada BETWEEN 5 AND 39 AND m.ratioCalidad >= 50 THEN 1.0
            ELSE 0
        END AS precioUniCalidadAdi
    FROM #MetricasCalculadas m;

    -- Calcular bonos de rango
    UPDATE b
    SET
        rango_actual = m.nivel_rango,
        tipo_bono = CASE
            WHEN m.nivel_rango > ISNULL(rango_ant.RANGO_MES_ANTERIOR, 0) THEN 'sube'
            WHEN m.nivel_rango = ISNULL(rango_ant.RANGO_MES_ANTERIOR, 0) AND m.nivel_rango > 0 THEN 'mantiene'
            ELSE NULL
        END,
        bono_rango = CASE
            WHEN m.ratio >= m.RATIO_MIN AND m.nivel_rango > ISNULL(rango_ant.RANGO_MES_ANTERIOR, 0) THEN ISNULL(br.bono, 0)
            WHEN m.ratio >= m.RATIO_MIN AND m.nivel_rango = ISNULL(rango_ant.RANGO_MES_ANTERIOR, 0) AND m.nivel_rango > 0 THEN ISNULL(br.bono, 0)
            ELSE 0
        END
    FROM #BonosCalculados b
    INNER JOIN #MetricasCalculadas m ON b.DNI_RESPONSABLE = m.DNI_RESPONSABLE
    LEFT JOIN (
        SELECT
            e2.DNI_RESPONSABLE,
            CASE
                WHEN e2.RANGO IS NULL OR e2.RANGO = '' THEN 0
                ELSE TRY_CAST(REPLACE(REPLACE(e2.RANGO, 'RANGO ', ''), 'R', '') AS INT)
            END AS RANGO_MES_ANTERIOR
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e2
        WHERE e2.AÑO = @año AND e2.MES = @mes
    ) rango_ant ON rango_ant.DNI_RESPONSABLE = m.DNI_RESPONSABLE
    LEFT JOIN dbo.BonoRango br ON
        br.nivel_rango = rango_ant.RANGO_MES_ANTERIOR
        AND @fechaPeriodo BETWEEN br.fecha_inicio AND ISNULL(br.fecha_fin, @fechaPeriodo)
        AND (
            (m.nivel_rango > ISNULL(rango_ant.RANGO_MES_ANTERIOR, 0) AND br.tipo_bono = 'sube')
            OR
            (m.nivel_rango = ISNULL(rango_ant.RANGO_MES_ANTERIOR, 0) AND m.nivel_rango > 0 AND br.tipo_bono = 'mantiene')
        );

    -- Calcular bonos totales
    UPDATE b
    SET
        bonoCalidad = (m.TOTAL_VCALIDAD * b.precioUniCalidadAdi),
        bonoRecargaPre = (m.TOTAL_RECARGAS * 2.00),
        bonoPortaPre = (m.cantPrepagoPorta * 4),
        bonoPortaPostOPost = (m.cantidadPortaPostOPost * 35),
        bonoPortaPostOPre = (m.cantidadPortaPostOPre * 20),
        bonoTotalEfectivo = (
            ISNULL((b.BONO_UNITARIO_EQUIPO * m.VentaPrepagoLimitada), 0) +
            ISNULL((m.TOTAL_RECARGAS * 2.00), 0) +
            ISNULL((m.cantPrepagoPorta * 4), 0) +
            ISNULL((m.cantidadPortaPostOPost * 35), 0) +
            ISNULL((m.cantidadPortaPostOPre * 20), 0) +
            ISNULL((m.TOTAL_VCALIDAD * b.precioUniCalidadAdi), 0) +
            ISNULL(b.bono_rango, 0)
        ),
        bonoTotal = (
            ISNULL((b.BONO_UNITARIO_EQUIPO * m.VentaPrepagoLimitada), 0) +
            ISNULL((m.TOTAL_RECARGAS * 2.00), 0) +
            ISNULL((m.cantPrepagoPorta * 4), 0) +
            ISNULL((m.cantidadPortaPostOPost * 35), 0) +
            ISNULL((m.cantidadPortaPostOPre * 20), 0) +
            ISNULL((m.TOTAL_VCALIDAD * b.precioUniCalidadAdi), 0) +
            ISNULL(b.bonoDevolucionChips, 0) +
            ISNULL(b.bono_rango, 0)
        )
    FROM #BonosCalculados b
    INNER JOIN #MetricasCalculadas m ON b.DNI_RESPONSABLE = m.DNI_RESPONSABLE;

    DROP TABLE #BonoEscalaFiltrada;

    -- ============================================
    -- ETAPA 3: INSERTAR DIRECTAMENTE EN RESUMEN
    -- ============================================

    -- Eliminar registros existentes
    DELETE FROM dbo.PDV_OUT_ESQUEMA_RESUMEN WHERE AÑO = @año AND MES = @mes;

    -- Insertar resultado final consolidado
    INSERT INTO dbo.PDV_OUT_ESQUEMA_RESUMEN (
        DNI_RESPONSABLE, AÑO, MES,
        NOMBRE_RESPONSABLE, ZONAL, ACCION_1, ACCION_2, RANGO_MES_ANTERIOR,
        TOTAL_RECARGAS, TOTAL_VCALIDAD, PRE_PORTA, PORTAPRE, PORTAPOS,
        DIAS_VENTAS_RESPONSABLE, VENTAS_MES_ANTERIOR, VENTA_AVANCE_PREPAGO, VENTA_PREPAGO_CALIDAD,
        cantidadAltaPost, cantidadPortaPostOPost, cantidadPortaPostOPre, cantPrepagoPorta,
        bonoChips, BONO_UNITARIO_EQUIPO, bonoDevolucionChips, precioUniCalidadAdi,
        bonoCalidad, bonoRecargaPre, bonoPortaPre, bonoPortaPostOPost, bonoPortaPostOPre,
        nivel_rango, rango_actual, tipo_bono, bono_rango, ratio_min_requerido,
        bonoTotalEfectivo, bonoTotal,
        VentaPrepagoLimitada, VentaPrepagoCalidadLimitada, ratio, ratioCalidad, MAX_VENTA
    )
    SELECT
        e.DNI_RESPONSABLE,
        @año AS AÑO,
        @mes AS MES,
        e.NOMBRE_RESPONSABLE,
        e.ZONAL,
        e.ACCION_1,
        e.ACCION_2,
        CASE
            WHEN e.RANGO IS NULL OR e.RANGO = '' THEN 0
            ELSE TRY_CAST(REPLACE(REPLACE(e.RANGO, 'RANGO ', ''), 'R', '') AS INT)
        END AS RANGO_MES_ANTERIOR,
        m.TOTAL_RECARGAS,
        m.TOTAL_VCALIDAD,
        m.PRE_PORTA,
        m.PORTAPRE,
        m.PORTAPOS,
        m.DIAS_VENTAS_RESPONSABLE,
        m.VENTAS_MES_ANTERIOR,
        m.VENTA_AVANCE_PREPAGO,
        m.VENTA_PREPAGO_CALIDAD,
        m.cantidadAltaPost,
        m.cantidadPortaPostOPost,
        m.cantidadPortaPostOPre,
        m.cantPrepagoPorta,
        m.VentaPrepagoLimitada AS bonoChips,
        ISNULL(b.BONO_UNITARIO_EQUIPO, 0) AS BONO_UNITARIO_EQUIPO,
        ISNULL(b.bonoDevolucionChips, 0) AS bonoDevolucionChips,
        ISNULL(b.precioUniCalidadAdi, 0) AS precioUniCalidadAdi,
        ISNULL(b.bonoCalidad, 0) AS bonoCalidad,
        ISNULL(b.bonoRecargaPre, 0) AS bonoRecargaPre,
        ISNULL(b.bonoPortaPre, 0) AS bonoPortaPre,
        ISNULL(b.bonoPortaPostOPost, 0) AS bonoPortaPostOPost,
        ISNULL(b.bonoPortaPostOPre, 0) AS bonoPortaPostOPre,
        m.nivel_rango,
        ISNULL(b.rango_actual, 0) AS rango_actual,
        b.tipo_bono,
        ISNULL(b.bono_rango, 0) AS bono_rango,
        m.RATIO_MIN AS ratio_min_requerido,
        ISNULL(b.bonoTotalEfectivo, 0) AS bonoTotalEfectivo,
        ISNULL(b.bonoTotal, 0) AS bonoTotal,
        m.VentaPrepagoLimitada,
        m.VentaPrepagoCalidadLimitada,
        m.ratio,
        m.ratioCalidad,
        m.MAX_VENTA
    FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE e
    INNER JOIN #MetricasCalculadas m ON e.DNI_RESPONSABLE = m.DNI_RESPONSABLE
    LEFT JOIN #BonosCalculados b ON e.DNI_RESPONSABLE = b.DNI_RESPONSABLE
    WHERE e.AÑO = @año AND e.MES = @mes AND e.ESTADO = 'ACTIVO';

    DROP TABLE #MetricasCalculadas;
    DROP TABLE #BonosCalculados;

    -- ============================================
    -- ETAPA 4: ACTUALIZAR PARÁMETRO DE FECHA MÁXIMA COMÚN
    -- ============================================
    -- Actualizar el parámetro tipo=9 con la fecha máxima común calculada
    -- Este parámetro puede ser usado por otros procesos para conocer hasta qué fecha
    -- se procesaron los datos en el último cálculo del esquema PDV.
    -- Se actualiza solo si los datos se insertaron correctamente (después de DROP TABLE).

    -- Actualizar o insertar el parámetro tipo=9 con la fecha máxima común
    DECLARE @fechaMaximaComunStr VARCHAR(10) = CONVERT(VARCHAR(10), @fechaMaximaComun, 120);
    DECLARE @fechaActualizacionStr VARCHAR(10) = CONVERT(VARCHAR(10), GETDATE(), 120);

    MERGE PORTAL_COMERCIAL.dbo.parametros AS destino
    USING (
        SELECT
            @fechaMaximaComunStr AS valor,
            'Fecha máxima común calculada por sp_ActualizarEsquemaPDV PARA ESQUEMA PDV Actualizado: ' + @fechaActualizacionStr AS comentario
    ) AS origen
    ON destino.tipo = 9 AND destino.[level] = 0
    WHEN MATCHED THEN
        UPDATE SET
            valor = origen.valor,
            comentario = origen.comentario
    WHEN NOT MATCHED THEN
        INSERT (tipo, [level], fecha, valor, comentario)
        VALUES (9, 0, NULL, origen.valor, origen.comentario);

    -- ============================================
    -- ETAPA 5: DEVOLVER CANTIDAD DE REGISTROS INSERTADOS
    -- ============================================
    DECLARE @cantidadRegistros INT;

    SELECT @cantidadRegistros = COUNT(*)
    FROM dbo.PDV_OUT_ESQUEMA_RESUMEN
    WHERE AÑO = @año AND MES = @mes;

    -- Devolver cantidad de registros insertados
    SELECT @cantidadRegistros AS cantidad_registros;

END;
