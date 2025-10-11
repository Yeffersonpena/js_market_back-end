-- SP para obtener datos base de multimarca (una sola fila)
-- Incluye: ventas, calidad, portabilidades - SIN datos de recargas por período
CREATE PROCEDURE [dbo].[spResumenBaseMultimarca]
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
	
	-- Obtener precios de portabilidad desde tabla de parámetros
	SET @precioPortaPrePago = dbo.fn_PrecioPortabilidadMM(@año, @mes, 'PREPAGO');
	SET @precioPortaPostPago = dbo.fn_PrecioPortabilidadMM(@año, @mes, 'POSTPAGO');
    select @dateCalFunnel=max(FECHA_CARGA) from BD_PLANIFICACION.dbo.PP2025_N0
    where year(FECHA_CARGA)=@año and month(FECHA_CARGA)=@mes; 
	
	SET @dateStart = DATEFROMPARTS(@año, @mes, 1);
	
	select @ventaLog= count(DISTINCT FECHA)  from PORTAL_COMERCIAL.dbo.PDV_OUT_FUNNEL where DNI_VENDEDOR =@dni
	and year(fecha)=@año and month(fecha)=@mes and PRODUCTO ='PREPAGO';
	
	select @dateUpdateCalidad=valor from dbo.parametros where tipo=4;
	select @recargaTotal =sum(RECARGA_TOTAL) FROM dbo.PDV_OUT_FUNNEL_RESUMEN_MM WHERE DNI_VENDEDOR = @dni and ANIO=@año and MES=@mes 
	-- Usar nueva función que maneja todos los casos desde tabla de parámetros
	SET @precioCalidad = dbo.fn_UnitarioCalidadMM(@dni, @dateStart, @dateUpdateCalidad);
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
	
	-- CTE para datos de portabilidad
	;WITH funnel AS (
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
	)
	-- Retornar datos base (una sola fila)
	SELECT 
	    @dni AS dni_vendedor,
	    @ventaLog AS ventasLog,
	    @cantidadCalidad AS cantidadCalidad,
	    @precioCalidad AS pagoUniCalidad,
	    ISNULL(@gananciaCalidad, 0) AS bonoCalidad,
	    COALESCE(fp.cantidadPortaPostOPre, 0) AS cantidadPortaPostOPre,
	    COALESCE(fp.precioPortaPostOPre, 0) AS precioPortaPostOPre,
	    COALESCE(fp.cantidadPortaPostOPost, 0) AS cantidadPortaPostOPost,
	    COALESCE(fp.precioPortaPostOPost, 0) AS precioPortaPostOPost,
	    COALESCE(fp.bonoPortaPostOPre, 0) AS bonoPortaPostOPre,
	    COALESCE(fp.bonoPortaPostOPost, 0) AS bonoPortaPostOPost,
	    COALESCE(fp.bonoPortaPostOPre, 0) + COALESCE(fp.bonoPortaPostOPost, 0) + ISNULL(@gananciaCalidad, 0) AS bonoTotalBase
	FROM (SELECT 1 AS dummy) AS base
	LEFT JOIN funnel fp ON fp.DNI_VENDEDOR = @dni;

END
