CREATE PROCEDURE [dbo].[spResumenGanaciaCampaña_MM_Payment]
    @dni INT,
    @año INT,
    @mes INT
AS
BEGIN
    SET NOCOUNT ON;
	
	declare @cantidadCalidad int, @ventaLog int, @recargaTotal int, @gananciaCalidad int, @dateUpdateCalidad date, @dateStart date;
	declare @precioCalidad int, @n0 decimal(10,2);
    declare @dateCalFunnel date;
	-- Variables para precios de portabilidad
	DECLARE @precioPortaPrePago DECIMAL(10,2);
	DECLARE @precioPortaPostPago DECIMAL(10,2);
	
	-- Asignar valores según el periodo
	IF (@año = 2025 AND @mes >= 9) OR @año > 2025
	BEGIN
	    SET @precioPortaPrePago = 40.00;
	    SET @precioPortaPostPago = 40.00;
	END
	ELSE
	BEGIN
	    SET @precioPortaPrePago = 20.00;
	    SET @precioPortaPostPago = 35.00;
	END
    select @dateCalFunnel=max(FECHA_CARGA) from BD_PLANIFICACION.dbo.PP2025_N0
    where year(FECHA_CARGA)=@año and month(FECHA_CARGA)=@mes; 
	
	SET @dateStart = DATEFROMPARTS(@año, @mes, 1);
	
	/*COMENTADO POR JC 20-08 select @ventaLog=count(*) from dbo.tbl_ventas_prepago_MM 
	where dni_vendedor=@dni AND YEAR(fecha)=@año and month(fecha)=@mes;*/
	
	select @ventaLog= count(DISTINCT FECHA)  from PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL where DNI_VENDEDOR =@dni
	and year(fecha)=@año and month(fecha)=@mes and PRODUCTO ='PREPAGO';
	
	select @dateUpdateCalidad=valor from dbo.parametros where tipo=4;
	select @recargaTotal =sum(RECARGA_TOTAL) FROM dbo.PDV_OUT_FUNNEL_RESUMEN_MM WHERE DNI_VENDEDOR = @dni and ANIO=@año and MES=@mes 
	SET @precioCalidad = CASE 
		WHEN @mes BETWEEN 1 AND 6 THEN 10
		WHEN @mes = 7 THEN 8
		when @mes=8 then 5
		when @mes=9 then dbo.fn_UnitarioCalidadMM(@dni,@dateStart,@dateUpdateCalidad)
		ELSE 0
	END;
    -- 
	IF @mes = 6
        begin
        select @cantidadCalidad=qbc, @gananciaCalidad=PagoVentasBC, @n0=PagoRecargasNO  from dbo.VentasMultimarca where DNIVendedor=@dni;
	end
	else 
        begin
        select @cantidadCalidad=count(*) from dbo.PDV_OUT_FUNNEL where DNI_VENDEDOR=@dni and fecha between @dateStart and @dateUpdateCalidad and CALIDAD_CLUSTER in ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado');
        set @gananciaCalidad=@cantidadCalidad * @precioCalidad;
	end
	--
	IF @mes = 6
        BEGIN
        ;WITH CTE AS (
            SELECT PERIODO_EVALUACION, ISNULL(SUM(CASE WHEN MONTO_RECARGADO >= 1 THEN MONTO_RECARGADO ELSE 0 END), 0) AS MONTO_RECARGADO
            FROM BD_PLANIFICACION.dbo.PP2025_N0
            WHERE DNI_VENDEDOR = @dni
                AND fecha BETWEEN '2025-06-01' AND '2025-11-30'
                AND FECHA_CARGA = @dateCalFunnel
            GROUP BY PERIODO_EVALUACION
        )
        SELECT
            @dni AS dni_vendedor,
            @ventaLog AS ventasLog,
            @cantidadCalidad AS cantidadCalidad,
            @precioCalidad AS pagoUniCalidad,
            'N0' as PERIODO_EVALUACION,
            0 as MONTO_RECARGADO,
            @n0 AS ganaciaPorRecarga,
            @n0 AS bonoRecargaNxVendedorSubTotal, 
            ISNULL(@gananciaCalidad, 0) AS bonoCalidad,
            @n0 + @gananciaCalidad as bonoTotal
        FROM CTE;
    END
    ELSE
        BEGIN
        ;WITH CTE AS (
        SELECT PERIODO_EVALUACION, ISNULL(SUM(CASE WHEN MONTO_RECARGADO >= 1 THEN MONTO_RECARGADO ELSE 0 END), 0) AS MONTO_RECARGADO
        FROM BD_PLANIFICACION.dbo.PP2025_N0
        WHERE DNI_VENDEDOR = @dni
            AND fecha BETWEEN '2025-06-01' AND '2025-11-30'
            AND FECHA_CARGA = @dateCalFunnel
        GROUP BY PERIODO_EVALUACION
    ),
    /*funnel AS (
        SELECT 
            f.DNI_VENDEDOR,
            ISNULL(SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1.00 ELSE 0.00 END), 0) AS cantidadPortaPostOPre,
            ISNULL(MAX(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 20.00 ELSE 0.00 END), 0) AS precioPortaPostOPre,
            ISNULL(SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1.00 ELSE 0.00 END), 0) AS cantidadPortaPostOPost,
            ISNULL(MAX(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 35.00 ELSE 0.00 END), 0) AS precioPortaPostOPost,
            ISNULL(SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 20.00 ELSE 0.00 END), 0) AS bonoPortaPostOPre,
            ISNULL(SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 35.00 ELSE 0.00 END), 0) AS bonoPortaPostOPost
        FROM dbo.PDV_OUT_FUNNEL f 
        WHERE YEAR(f.fecha) = @año 
            AND MONTH(f.fecha) = @mes 
            AND f.DNI_VENDEDOR = @dni
        GROUP BY f.DNI_VENDEDOR
    ),*/
    funnel AS (
	    SELECT 
	        f.DNI_VENDEDOR,
	        ISNULL(SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1.00 ELSE 0.00 END), 0) AS cantidadPortaPostOPre,
	        @precioPortaPrePago AS precioPortaPostOPre,
	        ISNULL(SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1.00 ELSE 0.00 END), 0) AS cantidadPortaPostOPost,
	        @precioPortaPostPago AS precioPortaPostOPost,
	        ISNULL(SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN @precioPortaPrePago ELSE 0.00 END), 0) AS bonoPortaPostOPre,
	        ISNULL(SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN @precioPortaPostPago ELSE 0.00 END), 0) AS bonoPortaPostOPost
	    FROM dbo.PDV_OUT_FUNNEL f 
	    WHERE YEAR(f.fecha) = @año 
	        AND MONTH(f.fecha) = @mes 
	        AND f.DNI_VENDEDOR = @dni
	    GROUP BY f.DNI_VENDEDOR
	),
    -- CTE para generar filas base independientemente de los datos
    base_data AS (
        SELECT 
            @dni AS dni_vendedor,
            @ventaLog AS ventasLog,
            @cantidadCalidad AS cantidadCalidad,
            @precioCalidad AS pagoUniCalidad,
            COALESCE(cte.PERIODO_EVALUACION, 'N/A') AS PERIODO_EVALUACION,
            COALESCE(cte.MONTO_RECARGADO, 0) AS MONTO_RECARGADO,
            COALESCE(cte.MONTO_RECARGADO * 0.4, 0) AS ganaciaPorRecarga,
            COALESCE(SUM(cte.MONTO_RECARGADO * 0.4) OVER (), 0) AS bonoRecargaNxVendedorSubTotal,
            ISNULL(@gananciaCalidad, 0) AS bonoCalidad,
            COALESCE(fp.cantidadPortaPostOPre, 0) AS cantidadPortaPostOPre,
            COALESCE(fp.precioPortaPostOPre, 0) AS precioPortaPostOPre,
            COALESCE(fp.cantidadPortaPostOPost, 0) AS cantidadPortaPostOPost,
            COALESCE(fp.precioPortaPostOPost, 0) AS precioPortaPostOPost,
            COALESCE(fp.bonoPortaPostOPre, 0) AS bonoPortaPostOPre,
            COALESCE(fp.bonoPortaPostOPost, 0) AS bonoPortaPostOPost,
            COALESCE(fp.bonoPortaPostOPre, 0) + COALESCE(fp.bonoPortaPostOPost, 0) +
            COALESCE(SUM(cte.MONTO_RECARGADO * 0.4) OVER (), 0) + ISNULL(@gananciaCalidad, 0) AS bonoTotal
        FROM (SELECT 1 AS dummy) AS base
        LEFT JOIN CTE cte ON 1=1
        LEFT JOIN funnel fp ON fp.DNI_VENDEDOR = @dni
    )
    SELECT * FROM base_data;
    END

END