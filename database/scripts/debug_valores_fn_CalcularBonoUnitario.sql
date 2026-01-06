-- Query para ver qué valores se envían a fn_CalcularBonoUnitario_PDV
-- Cambiar @dni según el DNI que quieras investigar
DECLARE @dni INT = 43313973;
DECLARE @año INT = 2025;
DECLARE @mes INT = 12;

DECLARE @existResp BIT;
DECLARE @tipoPDV VARCHAR(30), @zonal VARCHAR(30), @maxVenta INT, @accion1 VARCHAR(50);
DECLARE @maxDateCalidad DATE;
DECLARE @fechaPeriodo DATE = DATEFROMPARTS(@año, @mes, 1);
DECLARE @zonalPattern VARCHAR(50) = 'TODAS';

-- Determinar si existe responsable
IF EXISTS (SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE DNI_RESPONSABLE = @dni AND AÑO = @año AND MES = @mes)
    SET @existResp = 1;
ELSE
    SET @existResp = 0;

-- Obtener tipo PDV y zonal
SELECT TOP 1
    @tipoPDV = ACCION_2,
    @zonal = zonal,
    @accion1 = ACCION_1
FROM dbo.PDV_OUT_ENTREGABLE
WHERE
    (@existResp = 1 AND DNI_RESPONSABLE = @dni AND AÑO = @año AND MES = @mes) OR
    (@existResp = 0 AND DNI_VENDEDOR = @dni AND AÑO = @año)
ORDER BY mes DESC;

-- Obtener maxVenta
SELECT @maxVenta = ISNULL(MAX(rango_max), 0)
FROM dbo.BonoEscala
WHERE tipo_pdv = CASE WHEN @tipoPDV LIKE 'PDV PREMIUM%' THEN 'PDV PREMIUM' ELSE @tipoPDV END
AND zonal_pattern = @zonalPattern
AND @fechaPeriodo BETWEEN fecha_inicio AND ISNULL(fecha_fin, @fechaPeriodo);

-- Obtener maxDateCalidad
SELECT @maxDateCalidad = TRY_CAST(valor AS DATE)
FROM dbo.parametros
WHERE tipo = 4;

IF @maxDateCalidad IS NULL
    SET @maxDateCalidad = EOMONTH(@fechaPeriodo);

-- Calcular valores (igual que en el SP original)
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
        ISNULL((SELECT SUM(cantidad) FROM dbo.tbl_venta_log v WHERE ((@existResp = 1 AND v.DNI_RESPONSABLE = @dni) OR (@existResp = 0 AND v.DNI_VENDEDOR = @dni)) AND YEAR(v.FECHA) = @año AND MONTH(v.FECHA) = @mes AND v.FECHA <= @maxDateCalidad AND v.PRODUCT_NAME = 'Prepago'), 0) AS VENTA_PREPAGO_CALIDAD,
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
        CASE WHEN VENTA_PREPAGO_CALIDAD > @maxVenta THEN @maxVenta ELSE VENTA_PREPAGO_CALIDAD END AS VentaPrepagoCalidadLimitada,
        FLOOR((CAST(RECARGA_TOTAL AS DECIMAL(10,2)) / NULLIF(CAST(VENTA_AVANCE_PREPAGO AS DECIMAL(10,2)), 0) * 100)) AS ratio,
        FLOOR((CAST(cantidadCalidad AS DECIMAL(10,2)) / NULLIF(CAST(VENTA_PREPAGO_CALIDAD AS DECIMAL(10,2)), 0) * 100)) AS ratioCalidad
    FROM CalculosBase
)
SELECT
    @dni AS DNI,
    @año AS Año,
    @mes AS Mes,
    @existResp AS existResp,
    @tipoPDV AS tipoPDV_Original,
    CASE WHEN @tipoPDV LIKE 'PDV PREMIUM%' THEN 'PDV REGULAR' ELSE @tipoPDV END AS tipoPDV_EnviadoAFuncion,
    @zonal AS zonal,
    @zonalPattern AS zonalPattern,
    @maxVenta AS maxVenta,
    @maxDateCalidad AS maxDateCalidad,
    c.VENTA_AVANCE_PREPAGO,
    c.VentaPrepagoLimitada AS VentaPrepagoLimitada_EnviadoAFuncion,
    c.RECARGA_TOTAL,
    c.ratio AS ratio_EnviadoAFuncion,
    c.cantidadCalidad AS cantidadCalidad_EnviadoAFuncion,
    -- Llamar a la función para ver qué devuelve
    dbo.fn_CalcularBonoUnitario_PDV(
        CASE WHEN @tipoPDV LIKE 'PDV PREMIUM%' THEN 'PDV REGULAR' ELSE @tipoPDV END,
        @zonal,
        c.VentaPrepagoLimitada,
        c.ratio,
        c.cantidadCalidad,
        @año,
        @mes
    ) AS precioUniSchema_Resultado,
    -- Verificar condiciones
    CASE
        WHEN c.VentaPrepagoLimitada < 5 THEN '❌ VentaPrepagoLimitada < 5 (mínimo requerido)'
        WHEN c.ratio < 30.00 THEN '❌ ratio < 30.00 (mínimo requerido)'
        WHEN c.cantidadCalidad < 0 THEN '❌ cantidadCalidad < 0'
        ELSE '✅ Todas las condiciones básicas se cumplen'
    END AS ValidacionCondiciones,
    -- Contar registros de BonoEscala que cumplen
    (SELECT COUNT(*)
     FROM dbo.BonoEscala b
     WHERE b.tipo_pdv = 'PDV REGULAR'
       AND b.zonal_pattern = @zonalPattern
       AND @fechaPeriodo BETWEEN b.fecha_inicio AND ISNULL(b.fecha_fin, @fechaPeriodo)
       AND c.VentaPrepagoLimitada >= b.rango_min
       AND c.ratio >= b.ratio_min
       AND c.cantidadCalidad >= ISNULL(b.cantidad_calidad_min, 0)
    ) AS RegistrosBonoEscalaQueCumplen
FROM CalculosFinales c;

