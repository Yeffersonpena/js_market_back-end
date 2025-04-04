USE [PORTAL_COMERCIAL]
GO

/****** Object:  StoredProcedure [dbo].[spViewInfoVendedorMM]    Script Date: 04/04/2025 04:23:34 p. m. ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[spViewInfoVendedorMM]
	@dni_Vendedor int,
	@año INT,
	@mes INT
AS
BEGIN
	SET NOCOUNT ON;
    DECLARE @ULTIMA_FECHA DATE, @RECARGA_TOTAL INT, @cantidaDayConVentasPre int, @AVANCE_PREPAGO INT;
	DECLARE @fechaInicio DATE,@fechaFin DATE, @fechaConsul date, @fechaNow date, @typeTbl int, @tipoQuincena int;
    
    set @fechaNow=FORMAT(GETDATE(), 'yyyy-MM-dd');
    IF day(@fechaNow)<=15
        set @tipoQuincena =1;
    ELSE 
        SET @tipoQuincena =2;
    -- new init 
    if @tipoQuincena =1
    begin
        set @fechaInicio=CAST(CONCAT(@año, '-', @mes, '-01') AS DATE);
        set @fechaFin= CAST(CONCAT(@año, '-', @mes, '-15') AS DATE);
    end
    else if @tipoQuincena =2
    begin
        set @fechaInicio=CAST(CONCAT(@año, '-', @mes, '-16') AS DATE);
        set @fechaFin= EOMONTH(CAST(CONCAT(@año, '-', @mes, '-01') AS DATE));
    end;
    -- 
	select @cantidaDayConVentasPre= count(*) from dbo.tbl_ventas_prepago_MM where dni_vendedor=@dni_Vendedor  AND fecha between @fechaInicio and @fechaFin;
	
    select @RECARGA_TOTAL = RECARGA_QUINCENAL_TOTAL
	FROM dbo.PDV_OUT_FUNNEL_RESUMEN_MM WHERE DNI_VENDEDOR = @dni_Vendedor and ANIO=@año and MES=@mes;
	select @ULTIMA_FECHA = valor from dbo.parametros WHERE tipo=1;

	SELECT @AVANCE_PREPAGO = SUM(cantidad) FROM dbo.tbl_venta_log
	WHERE DNI_VENDEDOR = @dni_Vendedor and PRODUCT_NAME ='Prepago' AND fecha between @fechaInicio and @fechaFin;

	SELECT DISTINCT 
	E.MES,
	E.[ZONAL],
	E.[DNI_RESPONSABLE],
	E.[DNI_VENDEDOR],
	--  E.[NOMBRE_RESPONSABLE],
	E.[NOMBRE_VENDEDOR],
	E.[NOMBRE_SUPERVISOR],
	E.FECHA_INICIO,
    --  E.NOMBRE_RESPONSABLE,
    --  E.DNI_RESPONSABLE,
    E.NOMBRE_VENDEDOR1,
    @ULTIMA_FECHA AS ULTIMA_FECHA,
    -- E.GRUPO AS 'CLUSTER_PDV_REGULAR',
    ISNULL(E.CELULAR_VENDEDOR, 0) AS 'CELULAR_VENDEDOR',
    E.CUOTA_PREPAGO,
    E.ACCION_2,
    @RECARGA_TOTAL AS RECARGA_TOTAL,
    @AVANCE_PREPAGO AS [AVANCE PREPAGO],
    @cantidaDayConVentasPre as cantidaDayConVentasPre
    -- CASE 
    --     WHEN E.ACCION_1 = 'PDV REGULAR' THEN 'PDV'
    --     ELSE E.ACCION_1
    -- END AS ACCION
	FROM dbo.PDV_OUT_ENTREGABLE E
	WHERE E.DNI_VENDEDOR = @dni_Vendedor ORDER BY E.MES DESC;
END
GO


