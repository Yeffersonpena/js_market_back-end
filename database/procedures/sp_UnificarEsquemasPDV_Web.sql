-- SP Unificado para poblar tabla PDV_VENTAS_BONOS
-- Combina lógica de SP de esquema Sin HC con cálculos de spCalculoPayment_10
-- Enfoque global: suma todos los eventos del equipo al responsable
-- Optimizado para poblar tabla web con datos pre-calculados

CREATE PROCEDURE dbo.sp_UnificarEsquemasPDV_Web
    @año INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Limpiar datos del período
    DELETE FROM PORTAL_COMERCIAL.dbo.PDV_VENTAS_BONOS 
    WHERE AÑO = @año AND MES = @mes;
    
    -- CTE base que combina todos los tipos de PDV
    WITH TodosLosPDV AS (
        SELECT DISTINCT 
            DNI_RESPONSABLE,
            NOMBRE_RESPONSABLE,
            ZONAL,
            CASE 
                WHEN ACCION_1 = 'PDV PREMIUM' THEN 'PDV PREMIUM'
                WHEN ACCION_1 = 'PDV REGULAR' THEN 'PDV REGULAR'
                ELSE ACCION_1
            END AS TIPO_PDV
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_ENTREGABLE
        WHERE AÑO = @año AND MES = @mes  
          AND ACCION_1 IN ('PDV PREMIUM', 'PDV REGULAR')
    ),
    
    -- CTE para eventos combinados (todos los tipos de PDV)
    EventosCombinados AS (
        -- Ventas prepago
        SELECT DNI_RESPONSABLE, DNI_VENDEDOR AS DNI_EJECUTOR, 'VENTA' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE YEAR(FECHA) = @año AND MONTH(FECHA) = @mes AND PRODUCT_NAME = 'Prepago'
        
        UNION ALL
        
        -- Portabilidades prepago (PRE_PORTA)
        SELECT DNI_RESPONSABLE, DNI_VENDEDOR AS DNI_EJECUTOR, 'PRE_PORTA' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.VentasLog
        WHERE YEAR(FECHA) = @año AND MONTH(FECHA) = @mes 
          AND PRODUCT_NAME = 'Prepago' 
          AND OPERATION_NAME='Portabilidad'
        
        UNION ALL
        
        -- Recargas
        SELECT DNI_RESPONSABLE, DNI_VENDEDOR AS DNI_EJECUTOR, 'RECARGA' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE YEAR(fecha) = @año AND MONTH(fecha) = @mes 
          AND RECARGA_SI_NO = 1 
          AND [RECARGAS>5] = 1 
          AND PRODUCTO_WEB IN ('PREPAGO M7', 'PORT PREPAGO M7')
        
        UNION ALL
        
        -- Ventas de Calidad
        SELECT DNI_RESPONSABLE, DNI_VENDEDOR AS DNI_EJECUTOR, 'VENTA_CALIDAD' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE YEAR(fecha) = @año AND MONTH(fecha) = @mes 
          AND CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')
        
        UNION ALL
        
        -- Portabilidades prepago desde PDV_OUT_FUNNEL
        SELECT DNI_RESPONSABLE, DNI_VENDEDOR AS DNI_EJECUTOR, 'PORTA_PRE' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE YEAR(fecha) = @año AND MONTH(fecha) = @mes 
          AND DNI_RESPONSABLE IS NOT NULL
          AND PRODUCTOORIGEN = 'PREPAGO' 
          AND PRODUCTO_WEB = 'PORT M4 NO DIR'
        
        UNION ALL
        
        -- Portabilidades postpago desde PDV_OUT_FUNNEL
        SELECT DNI_RESPONSABLE, DNI_VENDEDOR AS DNI_EJECUTOR, 'PORTA_POS' AS TIPO_EVENTO
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL
        WHERE YEAR(fecha) = @año AND MONTH(fecha) = @mes 
          AND DNI_RESPONSABLE IS NOT NULL
          AND PRODUCTOORIGEN = 'POSTPAGO' 
          AND PRODUCTO_WEB = 'PORT M4 NO DIR'
    ),
    
    -- CTE para eventos distribuidos (todos al responsable)
    EventosDistribuidos AS (
        SELECT 
            p.DNI_RESPONSABLE,
            p.NOMBRE_RESPONSABLE,
            p.ZONAL,
            p.TIPO_PDV,
            e.TIPO_EVENTO,
            'RESPONSABLE' AS TIPO_ACTOR
        FROM TodosLosPDV p
        INNER JOIN EventosCombinados e ON p.DNI_RESPONSABLE = e.DNI_RESPONSABLE
    ),
    
    -- CTE para métricas agregadas
    MetricasBase AS (
        SELECT 
            e.DNI_RESPONSABLE,
            e.NOMBRE_RESPONSABLE,
            e.ZONAL,
            e.TIPO_PDV,
            -- Ventas y cantidades
            SUM(CASE WHEN e.TIPO_EVENTO = 'VENTA' THEN 1 ELSE 0 END) AS VENTA_AVANCE_PREPAGO,
            SUM(CASE WHEN e.TIPO_EVENTO = 'RECARGA' THEN 1 ELSE 0 END) AS cantidadRecarga,
            SUM(CASE WHEN e.TIPO_EVENTO = 'VENTA_CALIDAD' THEN 1 ELSE 0 END) AS cantidadCalidad,
            SUM(CASE WHEN e.TIPO_EVENTO = 'PRE_PORTA' THEN 1 ELSE 0 END) AS cantidadPortaPre,
            SUM(CASE WHEN e.TIPO_EVENTO = 'PORTA_PRE' THEN 1 ELSE 0 END) AS cantidadPortaPre_Funnel,
            SUM(CASE WHEN e.TIPO_EVENTO = 'PORTA_POS' THEN 1 ELSE 0 END) AS cantidadPortaPostOPost,
            -- Campos adicionales para compatibilidad
            SUM(CASE WHEN e.TIPO_EVENTO = 'PRE_PORTA' THEN 1 ELSE 0 END) AS cantPrepagoPorta
        FROM EventosDistribuidos e
        GROUP BY e.DNI_RESPONSABLE, e.NOMBRE_RESPONSABLE, e.ZONAL, e.TIPO_PDV
    ),
    
    -- CTE para datos de postpago (alta postpago)
    PostpagoData AS (
        SELECT 
            f.DNI_RESPONSABLE,
            COUNT(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 1 END) AS cantidadAltaPost,
            COUNT(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 END) AS cantidadPortaPostOPost_Extra,
            COUNT(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 END) AS cantidadPortaPostOPre
        FROM PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL f
        WHERE YEAR(f.FECHA) = @año 
          AND MONTH(f.FECHA) = @mes 
          AND f.DNI_RESPONSABLE IS NOT NULL
          AND (
              f.PRODUCTO_WEB = 'POSTPAGO M4' 
              OR (f.PRODUCTO_WEB = 'PORT M4 NO DIR' AND f.PRODUCTOORIGEN IN ('PREPAGO', 'POSTPAGO'))
          )
        GROUP BY f.DNI_RESPONSABLE
    ),
    
    -- CTE para cálculos con límites y bonos
    CalculosCompletos AS (
        SELECT 
            m.*,
            ISNULL(pd.cantidadAltaPost, 0) AS cantidadAltaPost,
            ISNULL(pd.cantidadPortaPostOPost_Extra, 0) AS cantidadPortaPostOPost_Extra,
            ISNULL(pd.cantidadPortaPostOPre, 0) AS cantidadPortaPostOPre,
            
            -- Calcular ratios
            CASE 
                WHEN m.VENTA_AVANCE_PREPAGO > 0 
                THEN FLOOR((CAST(m.cantidadRecarga AS DECIMAL(10,2)) / CAST(m.VENTA_AVANCE_PREPAGO AS DECIMAL(10,2)) * 100))
                ELSE 0 
            END AS ratio,
            
            CASE 
                WHEN m.VENTA_AVANCE_PREPAGO > 0 
                THEN FLOOR((CAST(m.cantidadCalidad AS DECIMAL(10,2)) / CAST(m.VENTA_AVANCE_PREPAGO AS DECIMAL(10,2)) * 100))
                ELSE 0 
            END AS ratioCalidad,
            
            -- Determinar tipo PDV para BonoEscala
            CASE 
                WHEN m.TIPO_PDV LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM'
                ELSE m.TIPO_PDV
            END AS tipoPDV_BonoEscala,
            
            -- Mapear zona para BonoEscala
            CASE 
                WHEN m.ZONAL LIKE '%LIMA SUR%' THEN '%LIMA SUR%'
                WHEN m.TIPO_PDV = 'PDV REGULAR SIN HC' THEN 'TODAS'
                ELSE 'REGIONES'
            END AS zonalPattern
            
        FROM MetricasBase m
        LEFT JOIN PostpagoData pd ON m.DNI_RESPONSABLE = pd.DNI_RESPONSABLE
    ),
    
    -- CTE para obtener límites de BonoEscala
    CalculosConLimites AS (
        SELECT 
            c.*,
            -- Obtener límite máximo desde BonoEscala
            ISNULL(be.maxVenta, 0) AS maxVenta,
            -- Aplicar límite a ventas
            CASE 
                WHEN c.VENTA_AVANCE_PREPAGO > ISNULL(be.maxVenta, 0) 
                THEN ISNULL(be.maxVenta, 0) 
                ELSE c.VENTA_AVANCE_PREPAGO 
            END AS VentaPrepagoLimitada,
            -- Obtener precio unitario desde BonoEscala
            ISNULL(be.precioUnitario, 0) AS unitarioPrepago,
            -- Precio unitario por tipo PDV
            CASE 
                WHEN c.TIPO_PDV LIKE 'PDV PREMIUM%' THEN 3.00
                ELSE 2.00
            END AS unitarioRecargas
            
        FROM CalculosCompletos c
        LEFT JOIN (
            SELECT 
                tipo_pdv,
                zonal_pattern,
                MAX(rango_max) AS maxVenta,
                MAX(bono) AS precioUnitario
            FROM PORTAL_COMERCIAL.dbo.BonoEscala
            WHERE DATEFROMPARTS(@año, @mes, 1) BETWEEN fecha_inicio AND ISNULL(fecha_fin, DATEFROMPARTS(@año, @mes, 1))
            GROUP BY tipo_pdv, zonal_pattern
        ) be ON c.tipoPDV_BonoEscala = be.tipo_pdv 
            AND (
                (c.zonalPattern = '%LIMA SUR%' AND be.zonal_pattern LIKE '%LIMA SUR%') OR
                (c.zonalPattern != '%LIMA SUR%' AND be.zonal_pattern = c.zonalPattern)
            )
    ),
    
    -- CTE para cálculos finales de bonos
    BonosCalculados AS (
        SELECT 
            c.*,
            -- Bonos individuales
            c.VENTA_AVANCE_PREPAGO AS bonoDevolucionChips,
            (c.unitarioPrepago * c.VentaPrepagoLimitada) AS bonoPre,
            
            -- Precio unitario calidad adicional
            CASE 
                WHEN c.TIPO_PDV = 'PDV REGULAR SIN HC' AND c.VentaPrepagoLimitada BETWEEN 41 AND 100 AND c.ratioCalidad >= 50 THEN 1.5 
                WHEN c.TIPO_PDV = 'PDV REGULAR SIN HC' AND c.VentaPrepagoLimitada BETWEEN 5 AND 40 AND c.ratioCalidad >= 50 THEN 1.0
                WHEN c.TIPO_PDV LIKE 'PDV PREMIUM%' AND c.ZONAL LIKE '%LIMA SUR%' AND c.VentaPrepagoLimitada >= 100 THEN 4.5
                ELSE 0 
            END AS precioUniCalidadAdi,
            
            -- Bonos calculados
            (c.cantidadCalidad * 
                CASE 
                    WHEN c.TIPO_PDV = 'PDV REGULAR SIN HC' AND c.VentaPrepagoLimitada BETWEEN 41 AND 100 AND c.ratioCalidad >= 50 THEN 1.5 
                    WHEN c.TIPO_PDV = 'PDV REGULAR SIN HC' AND c.VentaPrepagoLimitada BETWEEN 5 AND 40 AND c.ratioCalidad >= 50 THEN 1.0
                    WHEN c.TIPO_PDV LIKE 'PDV PREMIUM%' AND c.ZONAL LIKE '%LIMA SUR%' AND c.VentaPrepagoLimitada >= 100 THEN 4.5
                    ELSE 0 
                END
            ) AS bonoCalidad,
            
            (c.cantidadRecarga * c.unitarioRecargas) AS bonoRecargaPre,
            (c.cantidadPortaPre * 4) AS bonoPortaPre,
            (c.cantidadAltaPost * 10) AS bonoAltaPost,
            (c.cantidadPortaPostOPost * 35) AS bonoPortaPostOPost,
            (c.cantidadPortaPostOPre * 20) AS bonoPortaPostOPre
            
        FROM CalculosConLimites c
    ),
    
    -- CTE para totales finales
    TotalesFinales AS (
        SELECT 
            b.*,
            -- Totales
            (
                ISNULL(b.bonoPre, 0) +
                ISNULL(b.bonoRecargaPre, 0) +
                ISNULL(b.bonoPortaPre, 0) +
                ISNULL(b.bonoAltaPost, 0) +
                ISNULL(b.bonoPortaPostOPost, 0) +
                ISNULL(b.bonoPortaPostOPre, 0) +
                ISNULL(b.bonoCalidad, 0)
            ) AS bonoTotalEfectivo,
            
            (
                ISNULL(b.bonoPre, 0) +
                ISNULL(b.bonoRecargaPre, 0) +
                ISNULL(b.bonoPortaPre, 0) +
                ISNULL(b.bonoAltaPost, 0) +
                ISNULL(b.bonoPortaPostOPost, 0) +
                ISNULL(b.bonoPortaPostOPre, 0) +
                ISNULL(b.bonoCalidad, 0) +
                ISNULL(b.bonoDevolucionChips, 0)
            ) AS bonoTotal
            
        FROM BonosCalculados b
    )
    
    -- Insertar en tabla PDV_VENTAS_BONOS
    INSERT INTO PORTAL_COMERCIAL.dbo.PDV_VENTAS_BONOS (
        DNI_RESPONSABLE, NOMBRE_RESPONSABLE, ZONAL, TIPO_PDV,
        AÑO, MES,
        VENTA_AVANCE_PREPAGO, cantidadRecarga, cantidadCalidad, cantidadPortaPre,
        cantidadAltaPost, cantidadPortaPostOPost, cantidadPortaPostOPre,
        cantPrepagoPorta, ratio, ratioCalidad, maxVenta, VentaPrepagoLimitada,
        unitarioPrepago, unitarioRecargas, precioUniCalidadAdi, faltaVenta,
        bonoDevolucionChips, bonoPre, bonoCalidad, bonoRecargaPre,
        bonoPortaPre, bonoAltaPost, bonoPortaPostOPost, bonoPortaPostOPre,
        bonoTotalEfectivo, bonoTotal, FECHA_CALCULO
    )
    SELECT 
        DNI_RESPONSABLE, NOMBRE_RESPONSABLE, ZONAL, TIPO_PDV,
        @año, @mes,
        VENTA_AVANCE_PREPAGO, cantidadRecarga, cantidadCalidad, cantidadPortaPre,
        cantidadAltaPost, cantidadPortaPostOPost, cantidadPortaPostOPre,
        cantPrepagoPorta, ratio, ratioCalidad, maxVenta, VentaPrepagoLimitada,
        unitarioPrepago, unitarioRecargas, precioUniCalidadAdi, 0,
        bonoDevolucionChips, bonoPre, bonoCalidad, bonoRecargaPre,
        bonoPortaPre, bonoAltaPost, bonoPortaPostOPost, bonoPortaPostOPre,
        bonoTotalEfectivo, bonoTotal, GETDATE()
    FROM TotalesFinales;
    
    -- Retornar resumen de procesamiento
    SELECT 
        COUNT(*) AS TotalRegistrosProcesados,
        SUM(VENTA_AVANCE_PREPAGO) AS TotalVentasPrepago,
        SUM(bonoTotal) AS TotalBonosCalculados
    FROM PORTAL_COMERCIAL.dbo.PDV_VENTAS_BONOS 
    WHERE AÑO = @año AND MES = @mes;
    
END;

-- =============================================
-- NOTAS DE USO:
-- =============================================
-- Este SP está diseñado para ejecutarse diariamente de lunes a viernes
-- Limpia y recalcula todos los datos del período especificado
-- 
-- Ejemplo de uso:
-- EXEC sp_UnificarEsquemasPDV_Web @año = 2024, @mes = 12;
--
-- El SP:
-- 1. Limpia datos existentes del período
-- 2. Recalcula todos los bonos y métricas
-- 3. Inserta datos actualizados en PDV_VENTAS_BONOS
-- 4. Retorna resumen de procesamiento
