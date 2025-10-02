CREATE PROCEDURE [dbo].[spViewInfoVendedor]
    @DNI int,  
    @ANIO INT,
    @MES INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @ULTIMA_FECHA DATE, @RECARGA_TOTAL INT;
    DECLARE @calidad_1 INT, @calidad_2 INT, @dateUpdateCalidad DATE, @dateStart date, @calidadAllNow int;
    DECLARE @existeResponsable BIT, @existeVendedorTblEntre BIT, @existeVendedorTblFunnel BIT;
	DECLARE @AVANCE_PREPAGO INT;
    DECLARE @dniResp INT, @nombre_2 NVARCHAR(255), @NOMBRE_RESPONSABLE NVARCHAR(255);
    declare @numeroCTA nvarchar(255), @banco nvarchar(255);
	SET @dateStart = DATEFROMPARTS(@ANIO, @MES, 1);

    select @numeroCTA = numero_cuenta_bancaria ,@banco=entidad_bancaria
	from PORTAL_COMERCIAL.dbo.tblpagos_datos_odoo 
	where CAST(numero_de_documento  AS BIGINT)=@DNI;
    IF EXISTS (
        SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE DNI_RESPONSABLE = @DNI AND  AÑO= @ANIO AND MES = @MES
    )
        SET @existeResponsable = 1;
    ELSE
        SET @existeResponsable = 0;

    IF @existeResponsable = 1
    BEGIN
        SELECT @RECARGA_TOTAL = sum(RECARGA_TOTAL) FROM dbo.PDV_OUT_FUNNEL_RESUMEN WHERE DNI_RESPONSABLE = @DNI AND ANIO = @ANIO AND MES = @MES
		AND (
			NOT EXISTS (
					SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE año = @ANIO AND mes = @MES AND DNI_VENDEDOR = dbo.PDV_OUT_FUNNEL_RESUMEN.DNI_VENDEDOR
				)
				OR EXISTS (
					SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE año = @ANIO AND mes = @MES AND DNI_VENDEDOR = dbo.PDV_OUT_FUNNEL_RESUMEN.DNI_VENDEDOR AND DNI_RESPONSABLE = @DNI
				)
			  );

		select @dateUpdateCalidad=valor from dbo.parametros where tipo=4;
		select @calidadAllNow=count(*) from dbo.PDV_OUT_FUNNEL where DNI_RESPONSABLE=@DNI and fecha between @dateStart and @dateUpdateCalidad and CALIDAD_CLUSTER in ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')

        SELECT @AVANCE_PREPAGO = SUM(cantidad) FROM dbo.tbl_venta_log WHERE DNI_RESPONSABLE = @DNI AND YEAR(FECHA) = @ANIO AND MONTH(FECHA) = @MES AND PRODUCT_NAME = 'Prepago'
		AND (
			NOT EXISTS (
					SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE año = @ANIO AND mes = @MES AND DNI_VENDEDOR = dbo.tbl_venta_log.DNI_VENDEDOR
				)
				OR EXISTS (
					SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE año = @ANIO AND mes = @MES AND DNI_VENDEDOR = dbo.tbl_venta_log.DNI_VENDEDOR AND DNI_RESPONSABLE = @DNI
				)
			  );
        SELECT DISTINCT TOP 1
            E.MES,
            E.NOMBRE_RESPONSABLE,
            E.DNI_RESPONSABLE,
            E.NOMBRE_VENDEDOR1,
            (SELECT valor FROM dbo.parametros WHERE tipo = 1) AS ULTIMA_FECHA,
            E.GRUPO AS CLUSTER_PDV_REGULAR,
            ISNULL(E.CELULAR_VENDEDOR, 0) AS CELULAR_VENDEDOR,
            E.CUOTA_PREPAGO,
            E.ACCION_2,
            @RECARGA_TOTAL AS RECARGA_TOTAL,
            @AVANCE_PREPAGO AS [AVANCE PREPAGO],
            CASE 
                WHEN E.ACCION_1 = 'PDV REGULAR' THEN 'PDV'
                ELSE E.ACCION_1
            END AS ACCION,
            @numeroCTA as [CCTA BANCARIA MM],
            @banco as [ENTIDAD BANCARIA MM],
            --@calidad_1 + @calidad_2 AS CALIDAD_CLUSTER,
			@calidadAllNow AS CALIDAD_CLUSTER,
			@dateUpdateCalidad AS DATE_UPDATE_CALIDAD
        FROM dbo.PDV_OUT_ENTREGABLE E
        WHERE E.DNI_RESPONSABLE = @DNI
        ORDER BY E.MES DESC;
    END
    ELSE
        BEGIN
        IF EXISTS (
            SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE DNI_VENDEDOR = @DNI AND  AÑO= @ANIO AND MES = @MES
        )
            SET @existeVendedorTblEntre = 1;
        ELSE
            SET @existeVendedorTblEntre = 0;
        -- 
        IF EXISTS (
            SELECT 1 FROM dbo.PDV_OUT_FUNNEL WHERE DNI_VENDEDOR= @DNI AND year(fecha) = @ANIO AND month(fecha)= @MES and SOCIO='JS MARKET'
        )
            SET @existeVendedorTblFunnel = 1;
        ELSE
            SET @existeVendedorTblFunnel = 0;
            
        IF @existeVendedorTblEntre = 1
            begin 
            SELECT @RECARGA_TOTAL = sum(RECARGA_TOTAL) FROM dbo.PDV_OUT_FUNNEL_RESUMEN WHERE DNI_RESPONSABLE = @DNI AND ANIO = @ANIO AND MES = @MES and DNI_VENDEDOR=@DNI
            AND (
                NOT EXISTS (
                 SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE año = @ANIO AND mes = @MES AND DNI_VENDEDOR = dbo.PDV_OUT_FUNNEL_RESUMEN.DNI_VENDEDOR
                    )
                    OR EXISTS (
                        SELECT 1 FROM dbo.PDV_OUT_ENTREGABLE WHERE año = @ANIO AND mes = @MES AND DNI_VENDEDOR = dbo.PDV_OUT_FUNNEL_RESUMEN.DNI_VENDEDOR AND DNI_RESPONSABLE = @DNI
                    )
                );


            select @dateUpdateCalidad=valor from dbo.parametros where tipo=4;

            select @calidadAllNow=count(*) from dbo.PDV_OUT_FUNNEL where DNI_VENDEDOR=@DNI and fecha between @dateStart and @dateUpdateCalidad and CALIDAD_CLUSTER in ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')

            SELECT @AVANCE_PREPAGO = SUM(cantidad) FROM dbo.tbl_venta_log
            WHERE DNI_VENDEDOR = @DNI AND YEAR(FECHA) = @ANIO AND MONTH(FECHA) = @MES AND PRODUCT_NAME = 'Prepago'


            SELECT DISTINCT TOP 1
                E.MES,
                E.NOMBRE_RESPONSABLE,
                E.DNI_RESPONSABLE,
                E.NOMBRE_VENDEDOR1,
                (SELECT valor FROM dbo.parametros WHERE tipo = 1) AS ULTIMA_FECHA,
                E.GRUPO AS CLUSTER_PDV_REGULAR,
                ISNULL(E.CELULAR_VENDEDOR, 0) AS CELULAR_VENDEDOR,
                E.CUOTA_PREPAGO,
                E.ACCION_2,
                @RECARGA_TOTAL AS RECARGA_TOTAL,
                @AVANCE_PREPAGO AS [AVANCE PREPAGO],
                CASE 
            WHEN E.ACCION_1 = 'PDV REGULAR' THEN 'PDV'
                    ELSE E.ACCION_1
                END AS ACCION,
                 @numeroCTA as [CCTA BANCARIA MM],
            	@banco as [ENTIDAD BANCARIA MM],
                --@calidad_1 + @calidad_2 AS CALIDAD_CLUSTER,
                @calidadAllNow AS CALIDAD_CLUSTER,
                @dateUpdateCalidad AS DATE_UPDATE_CALIDAD
            FROM dbo.PDV_OUT_ENTREGABLE E
            WHERE E.DNI_VENDEDOR = @DNI
            ORDER BY E.MES DESC;
        END
        ELSE 
            begin
            select @dateUpdateCalidad=valor from dbo.parametros where tipo=4;
            SELECT @RECARGA_TOTAL = COUNT(CASE WHEN RECARGA_SI_NO =1 and [RECARGAS>5] = 1 AND PRODUCTO_WEB in ('PREPAGO M7','PORT PREPAGO M7') THEN FECHA END),
            @dniResp = DNI_RESPONSABLE
            FROM dbo.PDV_OUT_FUNNEL WHERE DNI_VENDEDOR= @DNI AND year(fecha) = @ANIO AND month(fecha)= @MES and SOCIO='JS MARKET'
            GROUP BY DNI_RESPONSABLE;

            select @calidadAllNow=count(*) from dbo.PDV_OUT_FUNNEL where DNI_VENDEDOR=@DNI and fecha between @dateStart and @dateUpdateCalidad and CALIDAD_CLUSTER in ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')

            SELECT @AVANCE_PREPAGO = SUM(cantidad) FROM dbo.tbl_venta_log
            WHERE DNI_VENDEDOR = @DNI AND YEAR(FECHA) = @ANIO AND MONTH(FECHA) = @MES AND PRODUCT_NAME = 'Prepago'

            SELECT top 1 @nombre_2=DNI_RESPONSABLE, @NOMBRE_RESPONSABLE=NOMBRE_RESPONSABLE FROM dbo.PDV_OUT_ENTREGABLE WHERE DNI_RESPONSABLE =@dniResp  AND  AÑO= @ANIO AND MES = @MES
            
            ;WITH paymentOdo AS (
                select numero_de_documento, nombre_del_vendedor, tipo_plan, entidad_bancaria, numero_cuenta_bancaria from dbo.[tblpagos_datos_odoo] where numero_de_documento=@DNI
            )
            SELECT DISTINCT TOP 1
                -- E.MES,
                E.fecha,
                @nombre_2 as nombre_2,
                @NOMBRE_RESPONSABLE as NOMBRE_RESPONSABLE,
                E.DNI_RESPONSABLE,
                pay.nombre_del_vendedor as NOMBRE_VENDEDOR1,
                (SELECT valor FROM dbo.parametros WHERE tipo = 1) AS ULTIMA_FECHA,
                -- E.GRUPO AS CLUSTER_PDV_REGULAR,
                '0' AS CLUSTER_PDV_REGULAR, 
                -- ISNULL(E.CELULAR_VENDEDOR, 0) AS CELULAR_VENDEDOR,
                '' AS CELULAR_VENDEDOR,
                0 as CUOTA_PREPAGO,
                E.ACCION as ACCION_2,
           @RECARGA_TOTAL AS RECARGA_TOTAL,
                @AVANCE_PREPAGO AS [AVANCE PREPAGO],
                E.ACCION as ACCION,
                 @numeroCTA as [CCTA BANCARIA MM],
            	@banco as [ENTIDAD BANCARIA MM],
                @calidadAllNow AS CALIDAD_CLUSTER,
                @dateUpdateCalidad AS DATE_UPDATE_CALIDAD,
                1 AS typeUser
            FROM dbo.PDV_OUT_FUNNEL E
            LEFT JOIN paymentOdo pay ON pay.numero_de_documento = E.DNI_VENDEDOR
            WHERE E.DNI_VENDEDOR = @DNI and SOCIO='JS MARKET' AND ACCION LIKE '%pdv%'
            ORDER BY E.fecha DESC;
        END
    END
END