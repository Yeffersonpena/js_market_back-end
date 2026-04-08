CREATE PROCEDURE [dbo].[spLoadFileFunnel_New]
AS
BEGIN
    BEGIN TRY
		DECLARE @año int, @mes int, @fechaActual date, @maxDateCalidad date;

		select top 1 @año= year(fecha), @mes=month(fecha) from dbo.PDV_OUT_TEMP_FUNNEL;
		delete from dbo.PDV_OUT_FUNNEL where YEAR(fecha)=@año  and month(fecha)=@mes;
        --
        insert into dbo.PDV_OUT_FUNNEL(
            ZONAL,REGION,SOCIO,DNI_RESPONSABLE,DNI_VENDEDOR,FECHA,PRODUCTO_WEB,PRODUCTOORIGEN,OPERADORCEDENTE,TELEFONO,TIPO_PREPAGO,
            CALIDAD_CLUSTER,FECHA_PRIMERA_RECARGA,DOCUMENTO_CLIENTE,VENTA_EXTRANJERO,MONTO_ACUMULADO_RECARGAS,PRODUCTO,RECARGA_SI_NO,
            MONTO_PRIMERA_RECARGA,[RECARGAS>5],ACCION,ACCION_INTERNA,VENTAS_REPETIDAS,TRIPLICADO_SI_NO
         )
        select
            ZONAL,REGION,SOCIO,DNI_RESPONSABLE,DNI_VENDEDOR,
			--FECHA,
			CASE
				--WHEN PRODUCTO_WEB IN ('PORT PREPAGO M7', 'PORT M4 NO DIR') THEN CONVERT(DATE, DATEADD(DAY, -1, FECHA))
				WHEN PRODUCTO_WEB IN ('PORT PREPAGO M7', 'PORT M4 NO DIR') AND DAY(FECHA) <> 1 THEN CONVERT(DATE, DATEADD(DAY, -1, FECHA))
				ELSE FECHA
			END AS FECHA,
			--CONVERT(DATE, DATEADD(DAY, -1, FECHA)) as FECHA,
			PRODUCTO_WEB,PRODUCTOORIGEN,OPERADORCEDENTE,TELEFONO,TIPO_PREPAGO,
            CALIDAD_CLUSTER,FECHA_PRIMERA_RECARGA,DOCUMENTO_CLIENTE,VENTA_EXTRANJERO,MONTO_ACUMULADO_RECARGAS,PRODUCTO,RECARGA_SI_NO,
            MONTO_PRIMERA_RECARGA,[RECARGAS>5],ACCION,ACCION_INTERNA,VENTAS_REPETIDAS,TRIPLICADO_SI_NO
            from dbo.PDV_OUT_TEMP_FUNNEL
            WHERE NOT (PRODUCTO_WEB IN ('PORT PREPAGO M7', 'PORT M4 NO DIR') AND DAY(FECHA) = 1)
			-- 3 tbl resumen
        select @fechaActual = max(fecha) from dbo.PDV_OUT_FUNNEL

			-- Actualizar la tabla de resumen con los datos cargados
		delete from dbo.PDV_OUT_FUNNEL_RESUMEN where ANIO=@año and MES=@mes;

        MERGE INTO dbo.PDV_OUT_FUNNEL_RESUMEN AS destino
        USING (
            SELECT
                DNI_RESPONSABLE,
                YEAR(FECHA) AS ANIO,
                MONTH(FECHA) AS MES,
                --MAX(FECHA) AS ULTIMA_FECHA,
				@fechaActual as ULTIMA_FECHA,
                ---COUNT(CASE WHEN [RECARGAS>5] = 1 THEN FECHA END) AS RECARGA_TOTAL
				COUNT(CASE WHEN RECARGA_SI_NO =1 and [RECARGAS>5] = 1 AND PRODUCTO_WEB in ('PREPAGO M7','PORT PREPAGO M7') THEN FECHA END) AS RECARGA_TOTAL
            FROM dbo.PDV_OUT_FUNNEL
            WHERE year(fecha)=@año and MONTH(FECHA) = @mes and DNI_RESPONSABLE is not null
            GROUP BY DNI_RESPONSABLE, YEAR(FECHA), MONTH(FECHA)
        ) AS origen
        ON destino.DNI_RESPONSABLE = origen.DNI_RESPONSABLE
           AND destino.ANIO = origen.ANIO
           AND destino.MES = origen.MES
        WHEN MATCHED THEN
            UPDATE SET
                destino.ULTIMA_FECHA = origen.ULTIMA_FECHA,
                destino.RECARGA_TOTAL = origen.RECARGA_TOTAL
        WHEN NOT MATCHED THEN
        INSERT (DNI_RESPONSABLE, ANIO, MES, ULTIMA_FECHA, RECARGA_TOTAL)
        VALUES (origen.DNI_RESPONSABLE, origen.ANIO, origen.MES, origen.ULTIMA_FECHA, origen.RECARGA_TOTAL);
        ---
        update dbo.parametros set valor= @fechaActual where tipo=1;
        --
        DELETE FROM dbo.tbl_funnel_resumen_post WHERE year(FECHA)=@año AND MONTH(FECHA)=@mes;

        -- Pre-calcular datos de entregables para optimizar rendimiento
        WITH EntregablesVendedores AS (
            SELECT DISTINCT
                DNI_VENDEDOR,
                DNI_RESPONSABLE,
                CASE
                    WHEN DNI_RESPONSABLE IS NOT NULL THEN 1
                    ELSE 0
                END AS TIENE_ENTREGABLE_CON_RESPONSABLE
            FROM dbo.PDV_OUT_ENTREGABLE
            WHERE año = @año AND mes = @MES
        )

        INSERT INTO dbo.tbl_funnel_resumen_post (DNI_RESPONSABLE, FECHA, ALTA_POSTPAGO, PORTA_POST_O_PRE, PORTA_POST_O_POS)
SELECT
            f.DNI_RESPONSABLE,
            CONVERT(DATE, f.FECHA) AS FECHA,
			--CONVERT(DATE, DATEADD(DAY, -1, FECHA)) AS FECHA,
            SUM(CASE WHEN f.PRODUCTO_WEB = 'POSTPAGO M4' THEN 1 ELSE 0 END) AS ALTA_POSTPAGO,
            SUM(CASE WHEN f.PRODUCTOORIGEN = 'PREPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 ELSE 0 END) AS PORTA_POST_O_PRE,
            SUM(CASE WHEN f.PRODUCTOORIGEN = 'POSTPAGO' AND f.PRODUCTO_WEB = 'PORT M4 NO DIR' THEN 1 ELSE 0 END) AS PORTA_POST_O_POS
        FROM dbo.PDV_OUT_FUNNEL f
        LEFT JOIN EntregablesVendedores ev ON ev.DNI_VENDEDOR = f.DNI_VENDEDOR
        WHERE f.DNI_RESPONSABLE IS NOT NULL
          AND year(f.FECHA) = @año
          AND MONTH(f.FECHA) = @mes
          AND (ev.DNI_VENDEDOR IS NULL OR ev.TIENE_ENTREGABLE_CON_RESPONSABLE = 1)
        GROUP BY f.DNI_RESPONSABLE, CONVERT(DATE, f.FECHA);

        --delete from dbo.PDV_OUT_TEMP_FUNNEL;
		update dbo.PDV_OUT_FUNNEL set dateUpdateFile=FORMAT(GETDATE(), 'yyyy-MM-dd') where YEAR(fecha)=@año and month(fecha)=@mes
		update dbo.parametros set valor=FORMAT(DATEADD(DAY, -1, GETDATE()), 'yyyy-MM-dd') where tipo=1;

		SELECT @maxDateCalidad=MAX(fecha)
		FROM (
		SELECT fecha, COUNT(*) AS Cantidad
		FROM dbo.PDV_OUT_FUNNEL
		WHERE SOCIO = 'JS MARKET'
			AND PRODUCTO_WEB LIKE '%PRE%'
			AND CALIDAD_CLUSTER IN ('Cluster 1: IMEI nuevo', 'Cluster 2: IMEI reutilizado')
			AND year(fecha) = @año
			AND month(fecha) = @mes
		GROUP BY fecha
		HAVING COUNT(*) > 100
		) AS subconsulta
		--print @maxDateCalidad;
		IF @maxDateCalidad IS NOT NULL
			update dbo.parametros set valor=FORMAT(@maxDateCalidad, 'yyyy-MM-dd') where tipo=4;

		--exec dbo.paRegistrarUsuariosMasivo;
        insert into dbo.tbl_log_procedimientos values ('spLoadFileEntregable', GETDATE());
        RETURN 0;
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();
    END CATCH
END
