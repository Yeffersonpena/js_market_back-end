CREATE PROCEDURE [dbo].[spCalculoPayment_10]
    @dni int,
    @año INT,
    @mes INT,
    @tipoQuincena INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Determinar rol y parámetros clave (sin cambios)
    DECLARE @existResp BIT;
    DECLARE @tipoPDV VARCHAR(30), @zonal VARCHAR(30), @maxVenta INT, @precioUniTypePdv DECIMAL(10,2);

    IF EXISTS (SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE DNI_RESPONSABLE = @dni AND AÑO = @año AND MES = @mes)
        SET @existResp = 1;
    ELSE
        SET @existResp = 0;

    SELECT TOP 1
        @tipoPDV = ACCION_2,
        @zonal = zonal,
        @precioUniTypePdv = CASE WHEN ACCION_1 = 'PDV REGULAR' THEN 2.00 WHEN ACCION_1 LIKE 'PDV PREMIUM%' THEN 3.00 ELSE 0.00 END
    FROM dbo.PDV_OUT_ENTREGABLE
    WHERE 
        (@existResp = 1 AND DNI_RESPONSABLE = @dni AND AÑO = @año AND MES = @mes) OR
        (@existResp = 0 AND DNI_VENDEDOR = @dni AND AÑO = @año)
    ORDER BY mes DESC;

    -- Calcular @maxVenta dinámicamente desde BonoEscala
    DECLARE @fechaPeriodo DATE = DATEFROMPARTS(@año, @mes, 1);
    DECLARE @zonalPattern VARCHAR(50);
    
    -- Mapear zona para BonoEscala
    SET @zonalPattern = CASE 
        WHEN @zonal LIKE '%LIMA SUR%' THEN '%LIMA SUR%'
        WHEN @tipoPDV = 'PDV REGULAR' THEN 'TODAS'
        ELSE 'REGIONES'
    END;
    
    -- Obtener el rango máximo desde BonoEscala
    SELECT @maxVenta = ISNULL(MAX(rango_max), 0)
    FROM dbo.BonoEscala
    WHERE tipo_pdv = CASE WHEN @tipoPDV LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM' ELSE @tipoPDV END
    AND (
        (@zonalPattern = '%LIMA SUR%' AND zonal_pattern LIKE @zonalPattern) OR
        (@zonalPattern != '%LIMA SUR%' AND zonal_pattern = @zonalPattern)
    )
    AND @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo);

    -- 2. CTE mejorado para traer todos los datos necesarios para la salida
    WITH CalculosBase AS (
        SELECT
            ISNULL((SELECT SUM(cantidad) FROM dbo.tbl_venta_log v WHERE ((@existResp = 1 AND v.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND v.DNI_VENDEDOR = @dni)) AND YEAR(v.FECHA) = @año AND MONTH(v.FECHA) = @mes AND v.PRODUCT_NAME = 'Prepago'), 0) AS VENTA_AVANCE_PREPAGO,
            ISNULL((SELECT count(*) FROM dbo.PDV_OUT_FUNNEL f WHERE ((@existResp = 1 AND f.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND f.DNI_VENDEDOR = @dni)) AND YEAR(f.fecha) = @año AND MONTH(f.fecha) = @mes AND f.CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')), 0) AS cantidadCalidad,
            ISNULL((SELECT sum(RECARGA_TOTAL) FROM dbo.PDV_OUT_FUNNEL_RESUMEN r WHERE ((@existResp = 1 AND r.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND r.DNI_VENDEDOR = @dni)) AND r.ANIO = @año AND r.MES = @mes), 0) AS RECARGA_TOTAL,
            ISNULL((SELECT sum(PORTA_PREPAGO) FROM dbo.tbl_ventas_prepago_new p WHERE ((@existResp = 1 AND p.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND p.DNI_VENDEDOR = @dni)) AND YEAR(p.FECHA) = @año AND MONTH(p.FECHA) = @mes), 0) AS cantPrepagoPorta,
            
            -- Cantidades y bonos Postpago (replicando la lógica original)
            ISNULL((SELECT SUM(f.ALTA_POSTPAGO) FROM dbo.tbl_funnel_resumen_post f WHERE @existResp = 1 AND f.DNI_RESPONSABLE = @dni AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes), 0) AS cantidadAltaPost,
            ISNULL((SELECT SUM(f.PORTA_POST_O_POS) FROM dbo.tbl_funnel_resumen_post f WHERE @existResp = 1 AND f.DNI_RESPONSABLE = @dni AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes), 0) AS cantidadPortaPostOPost,
            ISNULL((SELECT SUM(f.PORTA_POST_O_PRE) FROM dbo.tbl_funnel_resumen_post f WHERE @existResp = 1 AND f.DNI_RESPONSABLE = @dni AND YEAR(f.FECHA) = @año AND MONTH(f.FECHA) = @mes), 0) AS cantidadPortaPostOPre
    ),
    CalculosFinales AS (
        SELECT
            *,
            CASE WHEN VENTA_AVANCE_PREPAGO > @maxVenta THEN @maxVenta ELSE VENTA_AVANCE_PREPAGO END AS VentaPrepagoLimitada,
            FLOOR((CAST(RECARGA_TOTAL AS DECIMAL(10,2)) / NULLIF(CAST(VENTA_AVANCE_PREPAGO AS DECIMAL(10,2)), 0) * 100)) AS ratio,
            FLOOR((CAST(cantidadCalidad AS DECIMAL(10,2)) / NULLIF(CAST(VENTA_AVANCE_PREPAGO AS DECIMAL(10,2)), 0) * 100)) AS ratioCalidad
        FROM CalculosBase
    ),
    CalculosConFunciones AS (
        SELECT
            *,
            -- Calculamos una sola vez la función fn_CalcularBonoUnitario
            dbo.fn_CalcularBonoUnitario_PDV(@tipoPDV, @zonal, VentaPrepagoLimitada, ratio, cantidadCalidad, @año, @mes) AS precioUniSchema,
            -- Calculamos una sola vez la función fn_CalcularDevolucionChip
            dbo.fn_CalcularDevolucionChip(@tipoPDV, VentaPrepagoLimitada) AS bonoDevolucionChips,
            -- Calculamos una sola vez el precio unitario de calidad adicional
            (CASE 
                WHEN @tipoPDV = 'PDV REGULAR' AND VentaPrepagoLimitada BETWEEN 41 AND 100 AND ratioCalidad >= 50 THEN 1.5 
                WHEN @tipoPDV = 'PDV REGULAR' AND VentaPrepagoLimitada BETWEEN 5 AND 40 AND ratioCalidad >= 50 THEN 1.0
                WHEN @tipoPDV LIKE 'PDV PREMIUM%' AND @zonal LIKE '%LIMA SUR%' AND VentaPrepagoLimitada >= 100 THEN 4.5
                ELSE 0 
            END) AS precioUniCalidadAdi
        FROM CalculosFinales
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
            ISNULL((c.cantidadCalidad * c.precioUniCalidadAdi), 0)
        ) AS bonoTotalEfectivo,
        (
            ISNULL((c.precioUniSchema * c.VentaPrepagoLimitada), 0) +
            ISNULL((c.RECARGA_TOTAL * @precioUniTypePdv), 0) +
            ISNULL((c.cantPrepagoPorta * 4), 0) +
            ISNULL((c.cantidadPortaPostOPost * 35), 0) +
            ISNULL((c.cantidadPortaPostOPre * 20), 0) +
            ISNULL((c.cantidadCalidad * c.precioUniCalidadAdi), 0) +
            ISNULL(c.bonoDevolucionChips, 0)
        ) AS bonoTotal,
        @tipoPDV as tipo

    FROM CalculosConFunciones c;
END;