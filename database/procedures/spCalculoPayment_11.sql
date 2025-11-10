CREATE PROCEDURE [dbo].[spCalculoPayment_11]
    @dni int,
    @año INT,
    @mes INT,
    @tipoQuincena INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Determinar rol y parámetros clave (sin cambios)
    DECLARE @existResp BIT;
    DECLARE @tipoPDV VARCHAR(30), @zonal VARCHAR(30), @maxVenta INT, @precioUniTypePdv DECIMAL(10,2), @accion1 VARCHAR(50);
    DECLARE @rangoMesAnterior INT = 0;  -- Nuevo: rango del mes anterior desde PDV_OUT_ENTREGABLE
    DECLARE @maxDateCalidad DATE;  -- Fecha máxima de calidad para alinear cálculos
    DECLARE @ratioMin DECIMAL(5,2);  -- Ratio mínimo requerido para bono_rango

    IF EXISTS (SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE DNI_RESPONSABLE = @dni AND AÑO = @año AND MES = @mes)
        SET @existResp = 1;
    ELSE
        SET @existResp = 0;

    SELECT TOP 1
        @tipoPDV = ACCION_2,
        @zonal = zonal,
        @accion1 = ACCION_1,
        -- NOVIEMBRE 2025: Ambos tipos usan el mismo precio unitario de recargas (2.00)
        @precioUniTypePdv = CASE WHEN ACCION_1 IN ('PDV REGULAR', 'PDV PREMIUM') OR ACCION_1 LIKE 'PDV PREMIUM%' THEN 2.00 ELSE 0.00 END,
        -- Extraer número del campo RANGO (ej: "RANGO 1" → 1, "RANGO 2" → 2)
        @rangoMesAnterior = CASE 
            WHEN RANGO IS NULL OR RANGO = '' THEN 0
            ELSE TRY_CAST(REPLACE(REPLACE(RANGO, 'RANGO ', ''), 'R', '') AS INT)
        END
    FROM dbo.PDV_OUT_ENTREGABLE
    WHERE 
        (@existResp = 1 AND DNI_RESPONSABLE = @dni AND AÑO = @año AND MES = @mes) OR
        (@existResp = 0 AND DNI_VENDEDOR = @dni AND AÑO = @año)
    ORDER BY mes DESC;

    -- Calcular @maxVenta dinámicamente desde BonoEscala
    DECLARE @fechaPeriodo DATE = DATEFROMPARTS(@año, @mes, 1);
    DECLARE @zonalPattern VARCHAR(50);
    
    -- NOVIEMBRE 2025: Mapear zona para BonoEscala - Todos usan 'TODAS' (sin diferenciación por zonas)
    SET @zonalPattern = 'TODAS';
    
    -- NOVIEMBRE 2025: Obtener el rango máximo desde BonoEscala - Ambos tipos buscan con 'TODAS'
    SELECT @maxVenta = ISNULL(MAX(rango_max), 0)
    FROM dbo.BonoEscala
    WHERE tipo_pdv = CASE WHEN @tipoPDV LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM' ELSE @tipoPDV END
    AND zonal_pattern = @zonalPattern
    AND @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo);

    -- Obtener ratio_min del período desde BonoEscala (es el mismo para todos los rangos)
    SELECT @ratioMin = ISNULL(MIN(ratio_min), 0)
    FROM dbo.BonoEscala
    WHERE @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo);

    -- Obtener fecha máxima de calidad desde parámetros para alinear cálculos
    SELECT @maxDateCalidad = TRY_CAST(valor AS DATE)
    FROM dbo.parametros
    WHERE tipo = 4;
    
    -- Si no hay fecha máxima de calidad, usar el último día del mes
    IF @maxDateCalidad IS NULL
        SET @maxDateCalidad = EOMONTH(@fechaPeriodo);

    -- 2. CTE optimizado para traer todos los datos necesarios para la salida
    WITH PostpagoData AS (
        SELECT 
            COUNT(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 1 END) AS cantidadAltaPost,
            COUNT(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 END) AS cantidadPortaPostOPost,
            COUNT(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 END) AS cantidadPortaPostOPre
        FROM dbo.PDV_OUT_FUNNEL f
        WHERE @existResp = 1 
          AND f.DNI_RESPONSABLE = @dni 
          AND YEAR(f.FECHA) = @año 
          AND MONTH(f.FECHA) = @mes 
          AND f.ACCION = @accion1
          AND (
              f.PRODUCTO_WEB = 'POSTPAGO M4' 
              OR (f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND f.PRODUCTOORIGEN IN ('PREPAGO', 'POSTPAGO'))
          )
    ),
    CalculosBase AS (
        SELECT
            ISNULL((SELECT SUM(cantidad) FROM dbo.tbl_venta_log v WHERE ((@existResp = 1 AND v.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND v.DNI_VENDEDOR = @dni)) AND YEAR(v.FECHA) = @año AND MONTH(v.FECHA) = @mes AND v.PRODUCT_NAME = 'Prepago'), 0) AS VENTA_AVANCE_PREPAGO,
            -- VENTA_PREPAGO_CALIDAD: ventas prepago hasta la fecha máxima de calidad para alinear con cantidadCalidad
            ISNULL((SELECT SUM(cantidad) FROM dbo.tbl_venta_log v WHERE ((@existResp = 1 AND v.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND v.DNI_VENDEDOR = @dni)) AND YEAR(v.FECHA) = @año AND MONTH(v.FECHA) = @mes AND v.FECHA <= @maxDateCalidad AND v.PRODUCT_NAME = 'Prepago'), 0) AS VENTA_PREPAGO_CALIDAD,
            -- cantidadCalidad: solo hasta la fecha máxima de calidad para alinear con ventas prepago
            ISNULL((SELECT count(*) FROM dbo.PDV_OUT_FUNNEL f WHERE ((@existResp = 1 AND f.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND f.DNI_VENDEDOR = @dni)) AND YEAR(f.fecha) = @año AND MONTH(f.fecha) = @mes AND f.fecha <= @maxDateCalidad AND f.CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado') AND f.ACCION = @accion1), 0) AS cantidadCalidad,
            ISNULL((SELECT COUNT(*) FROM dbo.PDV_OUT_FUNNEL f WHERE ((@existResp = 1 AND f.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND f.DNI_VENDEDOR = @dni)) AND YEAR(f.fecha) = @año AND MONTH(f.fecha) = @mes AND f.RECARGA_SI_NO = 1 AND f.[RECARGAS>5] = 1 AND f.PRODUCTO_WEB IN ('PREPAGO M7','PORT PREPAGO M7') AND f.ACCION = @accion1), 0) AS RECARGA_TOTAL,
            ISNULL((SELECT sum(PORTA_PREPAGO) FROM dbo.tbl_ventas_prepago_new p WHERE ((@existResp = 1 AND p.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND p.DNI_VENDEDOR = @dni)) AND YEAR(p.FECHA) = @año AND MONTH(p.FECHA) = @mes), 0) AS cantPrepagoPorta,
            ISNULL(pd.cantidadAltaPost, 0) AS cantidadAltaPost,
            ISNULL(pd.cantidadPortaPostOPost, 0) AS cantidadPortaPostOPost,
            ISNULL(pd.cantidadPortaPostOPre, 0) AS cantidadPortaPostOPre
        FROM PostpagoData pd
    ),
    CalculosFinales AS (
        SELECT
            *,
            CASE WHEN VENTA_AVANCE_PREPAGO > @maxVenta THEN @maxVenta ELSE VENTA_AVANCE_PREPAGO END AS VentaPrepagoLimitada,
            -- VentaPrepagoCalidadLimitada: ventas prepago limitadas hasta fecha máxima de calidad para cálculos de calidad
            CASE WHEN VENTA_PREPAGO_CALIDAD > @maxVenta THEN @maxVenta ELSE VENTA_PREPAGO_CALIDAD END AS VentaPrepagoCalidadLimitada,
            FLOOR((CAST(RECARGA_TOTAL AS DECIMAL(10,2)) / NULLIF(CAST(VENTA_AVANCE_PREPAGO AS DECIMAL(10,2)), 0) * 100)) AS ratio,
            -- ratioCalidad: usar VENTA_PREPAGO_CALIDAD para alinear con cantidadCalidad
            FLOOR((CAST(cantidadCalidad AS DECIMAL(10,2)) / NULLIF(CAST(VENTA_PREPAGO_CALIDAD AS DECIMAL(10,2)), 0) * 100)) AS ratioCalidad,
            -- Calcular nivel_rango para usar en bonoDevolucionChips
            (SELECT TOP 1 nivel_rango
             FROM dbo.BonoEscala
             WHERE tipo_pdv = CASE WHEN @tipoPDV LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM' ELSE @tipoPDV END
               AND zonal_pattern = @zonalPattern
               AND @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo)
               AND (CASE WHEN VENTA_AVANCE_PREPAGO > @maxVenta THEN @maxVenta ELSE VENTA_AVANCE_PREPAGO END) >= rango_min
               AND (CASE WHEN VENTA_AVANCE_PREPAGO > @maxVenta THEN @maxVenta ELSE VENTA_AVANCE_PREPAGO END) <= rango_max
             ORDER BY nivel_rango DESC) AS nivel_rango
        FROM CalculosBase
    ),
    CalculosConFunciones AS (
        SELECT
            c.*,
            -- NOVIEMBRE 2025: Calculamos una sola vez la función fn_CalcularBonoUnitario
            -- PDV PREMIUM se calcula como PDV REGULAR (mismas reglas)
            dbo.fn_CalcularBonoUnitario_PDV(
                CASE WHEN @tipoPDV LIKE 'PDV PREMIUM%' THEN 'PDV REGULAR' ELSE @tipoPDV END, 
                @zonal, 
                c.VentaPrepagoLimitada, 
                c.ratio, 
                c.cantidadCalidad, 
                @año, 
                @mes
            ) AS precioUniSchema,
            -- NOVIEMBRE 2025: bonoDevolucionChips cambia la lógica - solo se paga si nivel_rango >= 2
            -- Para otros períodos usa la función fn_CalcularDevolucionChip
            CASE 
                WHEN @año = 2025 AND @mes = 11 THEN
                    CASE WHEN c.nivel_rango >= 2 THEN c.VentaPrepagoLimitada ELSE 0 END
                ELSE
                    dbo.fn_CalcularDevolucionChip(
                        CASE WHEN @tipoPDV LIKE 'PDV PREMIUM%' THEN 'PDV REGULAR' ELSE @tipoPDV END, 
                        c.VentaPrepagoLimitada
                    )
            END AS bonoDevolucionChips,
            -- NOVIEMBRE 2025: Calculamos una sola vez el precio unitario de calidad adicional (Bono C1+C2)
            -- Ambos tipos (PDV REGULAR y PDV PREMIUM) usan las mismas reglas
            -- Usar VentaPrepagoCalidadLimitada para alinear con cantidadCalidad y ratioCalidad
            (CASE 
                WHEN c.VentaPrepagoCalidadLimitada BETWEEN 50 AND 150 AND c.ratioCalidad >= 50 THEN 1.5 
                WHEN c.VentaPrepagoCalidadLimitada BETWEEN 5 AND 49 AND c.ratioCalidad >= 50 THEN 1.0
                ELSE 0 
            END) AS precioUniCalidadAdi
        FROM CalculosFinales c
    ),
    CalculosConBonoRango AS (
        SELECT
            c.*,
            -- Calcular bono por rango usando la función especializada
            -- Alta cohesión: toda la lógica está en fn_CalcularBonoRango
            br.rango_mes_anterior,
            br.rango_actual,
            br.tipo_bono,
            br.bono_rango
        FROM CalculosConFunciones c
        CROSS APPLY dbo.fn_CalcularBonoRango(
            @rangoMesAnterior,  -- Rango del mes anterior desde PDV_OUT_ENTREGABLE
            c.nivel_rango,      -- Rango actual calculado en base a ventas
            @año,               -- Año actual
            @mes,               -- Mes actual
            c.ratio             -- Ratio de recargas para validar ratio_min
        ) br
    )
    -- 3. SELECT final, usando los valores precalculados
    SELECT
        c.VentaPrepagoLimitada AS bonoChips,
        @zonal AS zonal,
        @tipoPDV AS tipoPDV,
        c.RECARGA_TOTAL AS cantidadRecarga,
        c.cantidadCalidad,
        c.cantPrepagoPorta AS cantidadPortaPre,
        4 AS precioUniPortaPre, -- Valor fijo del SP original
        -- Recreando campos que eran fijos o dependían del rol
        IIF(@existResp = 1, 0, c.cantidadAltaPost) AS cantidadAltaPost,
        IIF(@existResp = 1, 0, 10) AS precioUniAltaPost, -- Valor fijo del SP original
        c.cantidadPortaPostOPost,
        35 AS precioPortaPostOPost, -- Valor fijo del SP original
        c.cantidadPortaPostOPre,
        20 AS precioPortaPostOPre, -- Valor fijo del SP original
        0 AS faltaVenta, -- Valor fijo del SP original

        -- Campos que usan los valores precalculados
        c.bonoDevolucionChips,
        c.precioUniSchema,
        @precioUniTypePdv as levelUser,

        -- Bonos calculados usando valores precalculados
        (c.precioUniSchema * c.VentaPrepagoLimitada) AS bonoPre,
        c.precioUniCalidadAdi,
        (c.cantidadCalidad * c.precioUniCalidadAdi) as bonoCalidad,
        (c.RECARGA_TOTAL * @precioUniTypePdv) AS bonoRecargaPre,
        (c.cantPrepagoPorta * 4) AS bonoPortaPre,
        IIF(@existResp = 1, 0, c.cantidadAltaPost * 10) AS bonoAltaPost,
        (c.cantidadPortaPostOPost * 35) AS bonoPortaPostOPost,
        (c.cantidadPortaPostOPre * 20) AS bonoPortaPostOPre,

        -- Totales usando valores precalculados
        (
            ISNULL((c.precioUniSchema * c.VentaPrepagoLimitada), 0) +
            ISNULL((c.RECARGA_TOTAL * @precioUniTypePdv), 0) +
            ISNULL((c.cantPrepagoPorta * 4), 0) +
            ISNULL((c.cantidadPortaPostOPost * 35), 0) +
            ISNULL((c.cantidadPortaPostOPre * 20), 0) +
            ISNULL((c.cantidadCalidad * c.precioUniCalidadAdi), 0) +
            ISNULL(c.bono_rango, 0)  -- Incluir bono por rango en efectivo
        ) AS bonoTotalEfectivo,
        (
            ISNULL((c.precioUniSchema * c.VentaPrepagoLimitada), 0) +
            ISNULL((c.RECARGA_TOTAL * @precioUniTypePdv), 0) +
            ISNULL((c.cantPrepagoPorta * 4), 0) +
            ISNULL((c.cantidadPortaPostOPost * 35), 0) +
            ISNULL((c.cantidadPortaPostOPre * 20), 0) +
            ISNULL((c.cantidadCalidad * c.precioUniCalidadAdi), 0) +
            ISNULL(c.bonoDevolucionChips, 0) +
            ISNULL(c.bono_rango, 0)  -- Incluir bono por rango en total
        ) AS bonoTotal,
        @tipoPDV as tipo,
        c.nivel_rango,
        
        -- Campos nuevos para bonos por rango
        c.rango_mes_anterior,
        c.tipo_bono,
        c.bono_rango,
        
        -- Ratio mínimo requerido para bono_rango (para mostrar en frontend)
        @ratioMin AS ratio_min_requerido

    FROM CalculosConBonoRango c;
END;

