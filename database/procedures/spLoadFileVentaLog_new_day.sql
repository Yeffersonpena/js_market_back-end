




CREATE PROCEDURE [dbo].[spLoadFileVentaLog_new_day]
    @año INT,
    @mes INT,
    @day INT
AS
BEGIN
    BEGIN TRY
        ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        delete from dbo.tbl_venta_log where  year(fecha)=@año and month(fecha)=@mes and day(fecha)=@day;
		--
        INSERT INTO dbo.tbl_venta_log (DNI_VENDEDOR,DNI_RESPONSABLE,FECHA,OPERATION_NAME,PRODUCT_NAME,ACTIVITY_RESULT,cantidad)
        SELECT DNI_VENDEDOR,DNI_RESPONSABLE,FECHA,OPERACION AS OPERATION_NAME, PRODUCTO AS PRODUCT_NAME,'OK' AS ACTIVITY_RESULT, COUNT(*) AS cantidad
        FROM dbo.TempVentaLog where year(fecha)=@año and month(fecha)= @mes and day(fecha)=@day GROUP BY DNI_VENDEDOR,DNI_RESPONSABLE,FECHA,OPERACION,PRODUCTO;
        ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
        --Insert en la tabla resumen prepago
        --    DELETE from dbo.tbl_ventas_prepago  where FECHA in (select distinct fecha from #TempVentaLog);
        DELETE from dbo.tbl_ventas_prepago_new where year(fecha)=@año and month(fecha)=@mes and day(fecha)=@day;
        INSERT INTO dbo.tbl_ventas_prepago_new(DNI_RESPONSABLE, FECHA, ALTA_PREPAGO, PORTA_PREPAGO, DNI_VENDEDOR)
        SELECT
            DNI_RESPONSABLE,
            FECHA,
            SUM(CASE WHEN OPERATION_NAME = 'Alta' AND PRODUCT_NAME = 'Prepago' THEN cantidad ELSE 0 END) AS ALTA_PREPAGO,
            SUM(CASE WHEN OPERATION_NAME = 'Portabilidad' AND PRODUCT_NAME = 'Prepago' THEN cantidad ELSE 0 END) AS PORTA_PREPAGO,
			DNI_VENDEDOR
        FROM dbo.tbl_venta_log
        WHERE year(fecha)=@año and month(fecha)=@mes and day(fecha)=@day --FECHA in (select distinct fecha from #TempVentaLog)
        GROUP BY DNI_RESPONSABLE, DNI_VENDEDOR, FECHA;

        DELETE from dbo.tbl_ventas_prepago_MM where year(fecha)=@año and month(fecha)=@mes and day(fecha)=@day;
        INSERT INTO dbo.tbl_ventas_prepago_MM(DNI_RESPONSABLE, DNI_VENDEDOR, FECHA, ALTA_PREPAGO, PORTA_PREPAGO)
        SELECT
            DNI_RESPONSABLE,
            DNI_VENDEDOR,
            FECHA,
            SUM(CASE WHEN OPERATION_NAME = 'Alta' AND PRODUCT_NAME = 'Prepago' THEN cantidad ELSE 0 END) AS ALTA_PREPAGO,
            SUM(CASE WHEN OPERATION_NAME = 'Portabilidad' AND PRODUCT_NAME = 'Prepago' THEN cantidad ELSE 0 END) AS PORTA_PREPAGO
        FROM dbo.tbl_venta_log
        WHERE DNI_VENDEDOR is not null and year(fecha)=@año and month(fecha)=@mes and day(fecha)=@day
        GROUP BY DNI_RESPONSABLE, DNI_VENDEDOR, FECHA;
        ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

        insert into dbo.tbl_log_procedimientos values ('spLoadFileVentaLog_new_day', GETDATE());
        RETURN 0;
    END TRY
    BEGIN CATCH
        RETURN ERROR_MESSAGE();
    END CATCH
END
